# frozen_string_literal: true

module Api::V0
  class RolesController < ApiController
    before_action :set_role, only: [ :show, :update, :destroy ]

    # GET /api/v0/roles
    def index
      authorize Role, :index?

      result = Api::V0::Roles::ListRolesOperation.call(params.to_unsafe_h, current_user)

      if result.success
        roles = result.value[:roles]
        render json: {
          success: true,
          data: Api::V0::RoleBlueprint.render_as_hash(roles, view: :list)
        }, status: :ok
      else
        unprocessable_entity(result.errors)
      end
    end

    # GET /api/v0/roles/:id
    def show
      authorize @role, :show?

      result = Api::V0::Roles::GetRoleOperation.call(@role.id, current_user)

      if result.success
        render json: {
          success: true,
          data: Api::V0::RoleBlueprint.render_as_hash(result.value[:role], view: :detailed)
        }, status: :ok
      else
        not_found_response(result.errors)
      end
    end

    # POST /api/v0/roles
    def create
      authorize Role, :create?

      result = Api::V0::Roles::CreateRoleOperation.call(role_params, current_user)

      if result.success
        render json: {
          success: true,
          data: Api::V0::RoleBlueprint.render_as_hash(result.value[:role], view: :detailed)
        }, status: :created
      else
        unprocessable_entity(result.errors)
      end
    end

    # PATCH/PUT /api/v0/roles/:id
    def update
      authorize @role, :update?

      result = Api::V0::Roles::UpdateRoleOperation.call(role_params, @role.id, current_user)

      if result.success
        render json: {
          success: true,
          data: Api::V0::RoleBlueprint.render_as_hash(result.value[:role], view: :detailed)
        }, status: :ok
      else
        unprocessable_entity(result.errors)
      end
    end

    # DELETE /api/v0/roles/:id
    def destroy
      authorize @role, :destroy?

      result = Api::V0::Roles::DeleteRoleOperation.call(@role.id, current_user)

      if result.success
        render json: {
          success: true,
          data: { message: result.value[:message] }
        }, status: :ok
      else
        unprocessable_entity(result.errors)
      end
    end

    private

    def set_role
      @role = Role.find_by(id: params[:id])
      not_found_response("Role not found") unless @role
    end

    def role_params
      params.permit(role: [ :name, :description, permission_ids: [] ]).to_h.deep_symbolize_keys
    end

    def filter_params
      params.permit(:type, :sort).to_h.deep_symbolize_keys
    end
  end
end
