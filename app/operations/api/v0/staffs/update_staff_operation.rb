# frozen_string_literal: true

module Api::V0::Staffs
  class UpdateStaffOperation < BaseOperation
    contract do
      params do
        required(:id).filled(:integer)
        required(:venue_id).filled(:integer)
        optional(:name).maybe(:string)
        optional(:email).maybe(:string)
        optional(:role_id).maybe(:integer)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @venue = Venue.find_by(id: params[:venue_id])
      return Failure(:not_found) unless @venue

      return Failure(:forbidden) unless authorize?

      @membership = VenueMembership.includes(:user).where(venue: @venue).find_by(user_id: params[:id])
      return Failure(:not_found) unless @membership

      @staff_user = @membership.user

      if params[:role_id].present?
        @role = Role.find_by(id: params[:role_id])
        return Failure({ role_id: [ "Role not found" ] }) unless @role
        return Failure({ role_id: [ "Role does not belong to this venue" ] }) unless @role.venue_id == @venue.id
      end

      @email_changed = params[:email].present? && params[:email].to_s.strip.downcase != @staff_user.email

      yield update_user
      yield update_membership

      StaffMailer.invitation(@staff_user, @venue, nil).deliver_later if @email_changed

      Success(json: serialize)
    end

    private

    attr_reader :params, :current_user, :venue, :membership, :staff_user, :role

    def authorize?
      StaffPolicy.new(current_user, venue).update?
    end

    def update_user
      update_attrs = {}
      update_attrs[:full_name] = params[:name] if params[:name].present?
      update_attrs[:email] = params[:email] if params[:email].present?

      return Success(@staff_user) if update_attrs.empty?

      return Failure(@staff_user.errors.to_h) unless @staff_user.update(update_attrs)

      Success(@staff_user)
    end

    def update_membership
      return Success(@membership) unless @role

      return Failure(@membership.errors.to_h) unless @membership.update(role: @role)

      Success(@membership)
    end

    def serialize
      Api::V0::UserBlueprint.render_as_hash(staff_user)
    end
  end
end
