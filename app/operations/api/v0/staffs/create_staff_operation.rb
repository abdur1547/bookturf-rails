# frozen_string_literal: true

module Api::V0::Staffs
  class CreateStaffOperation < BaseOperation
    contract do
      params do
        required(:name).filled(:string)
        required(:venue_id).filled(:integer)
        required(:email).filled(:string)
        required(:role_id).filled(:integer)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @venue = Venue.find_by(id: params[:venue_id])
      return Failure(:not_found) unless @venue

      return Failure(:forbidden) unless authorize?

      @role = Role.find_by(id: params[:role_id])
      return Failure({ role_id: [ "Role not found" ] }) unless @role
      return Failure({ role_id: [ "Role does not belong to this venue" ] }) unless @role.venue_id == @venue.id

      yield find_or_create_user
      yield create_membership

      send_invitation_email
      Success(json: serialize)
    end

    private

    attr_reader :params, :current_user, :venue, :role, :staff_user, :temp_password

    def authorize?
      StaffPolicy.new(current_user, venue).create?
    end

    def find_or_create_user
      existing = User.find_by(email: params[:email].to_s.strip.downcase)

      if existing
        return Failure({ email: [ "User is already a member of this venue" ] }) if VenueMembership.exists?(user: existing, venue: @venue)

        @staff_user = existing
      else
        @temp_password = SecureRandom.hex(8)
        @staff_user = User.new(
          full_name: params[:name],
          email: params[:email],
          password: @temp_password,
          password_confirmation: @temp_password
        )
        return Failure(@staff_user.errors.to_h) unless @staff_user.save
      end

      Success(@staff_user)
    end

    def create_membership
      membership = VenueMembership.new(user: @staff_user, venue: @venue, role: @role)
      return Failure(membership.errors.to_h) unless membership.save

      Success(membership)
    end

    def send_invitation_email
      StaffMailer.invitation(@staff_user, @venue, @temp_password).deliver_later
    end

    def serialize
      Api::V0::UserBlueprint.render_as_hash(staff_user)
    end
  end
end
