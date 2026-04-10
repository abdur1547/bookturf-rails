# frozen_string_literal: true

module Api::V0::Roles
  class ListRolesOperation < BaseOperation
    contract do
      params do
        optional(:type).maybe(:string)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      authorize
      # Get all roles based on filters
      roles = filter_roles(params)

      # Sort roles
      roles = sort_roles(roles, params[:sort] || "name")

      Success(roles: roles, current_user: current_user)
    end

    private
    attr_reader :params, :current_user

    def authorize
      return Success() if RolePolicy.new(current_user, Role).index?
      Failure(:unauthorized)
    end

    def filter_roles(params)
      roles = Role.all

      # Filter by type
      if params[:type].present?
        case params[:type]
        when "system"
          roles = roles.system_roles
        when "custom"
          roles = roles.custom_roles
        end
      end

      roles
    end

    def sort_roles(roles, sort_field)
      case sort_field
      when "name"
        roles.alphabetical
      when "created_at"
        roles.order(created_at: :desc)
      else
        roles.alphabetical
      end
    end
  end
end
