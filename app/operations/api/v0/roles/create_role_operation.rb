# frozen_string_literal: true

module Api::V0::Roles
  class CreateRoleOperation < BaseOperation
    contract do
      params do
        required(:role).hash do
          required(:name).filled(:string)
          optional(:venue_id).maybe(:integer)
          optional(:permission_ids).maybe(:array)
        end
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user
      role_params = params[:role]

      return Failure(:forbidden) unless authorize

      venue = resolve_venue(role_params[:venue_id])
      return Failure(:not_found) unless venue

      result = Roles::CreateService.call(
        params: { name: role_params[:name], venue_id: venue.id },
        created_by: current_user
      )

      return Failure(errors: result.error) unless result.success?

      @role = result.data

      if role_params[:permission_ids].present?
        assign_result = Roles::AssignPermissionsService.call(
          role: @role,
          permission_ids: role_params[:permission_ids],
          assigned_by: current_user
        )

        return Failure(errors: assign_result.error) unless assign_result.success?
        @role.reload
      end

      json_data = serialize

      Success(role: @role, json: json_data)
    end

    private

    attr_reader :params, :current_user, :role

    def authorize
      RolePolicy.new(current_user, Role).create?
    end

    def resolve_venue(venue_id)
      if venue_id.present?
        current_user.owned_venues.find_by(id: venue_id)
      else
        current_user.owned_venues.first
      end
    end

    def serialize
      Api::V0::RoleBlueprint.render_as_hash(role, view: :detailed)
    end
  end
end
