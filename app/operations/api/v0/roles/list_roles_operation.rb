# frozen_string_literal: true

module Api::V0::Roles
  class ListRolesOperation < BaseOperation
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

      @roles = Role.where(venue: @venue).alphabetical
      Success(roles: @roles, json: serialize)
    end

    private

    attr_reader :params, :current_user, :roles, :venue

    def authorize?
      RolePolicy.new(current_user, venue).index?
    end

    def serialize
      Api::V0::RoleBlueprint.render_as_hash(roles)
    end
  end
end
