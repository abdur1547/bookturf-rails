# frozen_string_literal: true

module Api::V0::Roles
  class CreateRoleOperation < BaseOperation
    contract do
      params do
        required(:name).filled(:string)
        required(:venue_id).filled(:integer)
        required(:permission_ids).value(:array)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @venue = Venue.find_by(id: params[:venue_id])
      return Failure(:not_found) unless @venue

      return Failure(:forbidden) unless authorize?

      if params[:permission_ids].present?
        return Failure(errors: { permission_ids: [ "contains invalid or non-existent IDs" ] }) unless valid_permission_ids?(params[:permission_ids])
      end

      result = Roles::CreateService.call(
        params: { name: params[:name], venue_id: @venue.id },
        created_by: current_user
      )
      return Failure(errors: result.error) unless result.success?

      @role = result.data

      if params[:permission_ids].present?
        assign_result = Roles::AssignPermissionsService.call(
          role: @role,
          permission_ids: params[:permission_ids],
          assigned_by: current_user
        )
        return Failure(errors: assign_result.error) unless assign_result.success?
        @role.reload
      end

      Success(role: @role, json: serialize)
    end

    private

    attr_reader :params, :current_user, :venue, :role

    def authorize?
      RolePolicy.new(current_user, venue).create?
    end

    def valid_permission_ids?(ids)
      Permission.where(id: ids).count == ids.map(&:to_i).uniq.length
    end

    def serialize
      Api::V0::RoleBlueprint.render_as_hash(role)
    end
  end
end
