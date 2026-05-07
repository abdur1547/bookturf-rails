# frozen_string_literal: true

module Api::V0::Staffs
  class ListStaffsOperation < BaseOperation
    contract do
      params do
        required(:venue_id).filled(:integer)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @venue = Venue.find_by(id: params[:venue_id])
      return Failure(:not_found) unless @venue

      return Failure(:forbidden) unless authorize?

      @staff_users = User.joins(:venue_memberships).where(venue_memberships: { venue_id: @venue.id })
      Success(json: serialize)
    end

    private

    attr_reader :params, :current_user, :venue, :staff_users

    def authorize?
      StaffPolicy.new(current_user, venue).index?
    end

    def serialize
      Api::V0::UserBlueprint.render_as_hash(staff_users)
    end
  end
end
