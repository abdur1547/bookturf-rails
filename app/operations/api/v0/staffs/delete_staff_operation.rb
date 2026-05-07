# frozen_string_literal: true

module Api::V0::Staffs
  class DeleteStaffOperation < BaseOperation
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

      @membership = VenueMembership.includes(:user).where(venue: @venue).find_by(user_id: params[:id])
      return Failure(:not_found) unless @membership

      @staff_user = @membership.user
      @membership.destroy

      StaffMailer.access_removed(@staff_user, @venue).deliver_later

      Success(json: { message: "Staff member removed successfully" })
    end

    private

    attr_reader :params, :current_user, :venue, :membership, :staff_user

    def authorize?
      StaffPolicy.new(current_user, venue).destroy?
    end
  end
end
