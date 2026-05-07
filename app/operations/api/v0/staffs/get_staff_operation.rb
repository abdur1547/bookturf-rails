# frozen_string_literal: true

module Api::V0::Staffs
  class GetStaffOperation < BaseOperation
    contract do
      params do
        required(:id).filled(:integer)
        required(:venue_id).filled(:integer)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @venue = Venue.find_by(id: params[:venue_id])
      return Failure(:not_found) unless @venue

      return Failure(:forbidden) unless authorize?

      @staff_user = User.joins(:venue_memberships)
                        .where(venue_memberships: { venue_id: @venue.id })
                        .find_by(id: params[:id])
      return Failure(:not_found) unless @staff_user

      Success(json: serialize)
    end

    private

    attr_reader :params, :current_user, :venue, :staff_user

    def authorize?
      StaffPolicy.new(current_user, venue).show?
    end

    def serialize
      Api::V0::UserBlueprint.render_as_hash(staff_user)
    end
  end
end
