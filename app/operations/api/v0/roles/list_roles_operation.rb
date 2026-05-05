# frozen_string_literal: true

module Api::V0::Roles
  class ListRolesOperation < BaseOperation
    contract do
      params do
        optional(:venue_id).maybe(:integer)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      return Failure(:forbidden) unless authorize?

      @roles = scoped_roles
      @roles = @roles.where(venue_id: params[:venue_id]) if params[:venue_id].present?
      @roles = @roles.alphabetical
      json_data = serialize
      Success(roles: @roles, json: json_data)
    end

    private

    attr_reader :params, :current_user, :roles

    def authorize?
      RolePolicy.new(current_user, Role).index?
    end

    def scoped_roles
      RolePolicy::Scope.new(current_user, Role).resolve
    end

    def serialize
      Api::V0::RoleBlueprint.render_as_hash(roles, view: :list)
    end
  end
end
