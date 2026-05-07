# frozen_string_literal: true

module Api::V0::Roles
  class UpdateRoleOperation < BaseOperation
    contract do
      params do
        required(:id).filled(:string)
        optional(:name).filled(:string)
        optional(:permission_ids).value(:array)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @role = Role.find_by(id: params[:id])
      return Failure(:not_found) unless @role

      return Failure(:forbidden) unless authorize?

      update_params = { name: params[:name], permission_ids: params[:permission_ids] }.compact

      if update_params[:permission_ids].present?
        return Failure(errors: { permission_ids: ["contains invalid or non-existent IDs"] }) unless valid_permission_ids?(update_params[:permission_ids])
      end

      result = Roles::UpdateService.call(
        role: @role,
        params: update_params,
        updated_by: current_user
      )
      return Failure(errors: result.error) unless result.success?

      @role = result.data.reload
      Success(role: @role, json: serialize)
    end

    private

    attr_reader :params, :current_user, :role

    def authorize?
      RolePolicy.new(current_user, role).update?
    end

    def valid_permission_ids?(ids)
      Permission.where(id: ids).count == ids.map(&:to_i).uniq.length
    end

    def serialize
      Api::V0::RoleBlueprint.render_as_hash(role)
    end
  end
end
