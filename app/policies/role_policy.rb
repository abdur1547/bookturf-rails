# frozen_string_literal: true

class RolePolicy < ApplicationPolicy
  # List roles - Owner, Admin, Receptionist can view
  def index?
    user.owner? || user.admin? || user.receptionist?
  end

  # View role details - Owner, Admin can view
  def show?
    user.owner? || user.admin?
  end

  # Create custom role - Only Owner
  def create?
    user.owner?
  end

  # Update custom role - Only Owner
  def update?
    return false unless user.owner?
    # Cannot update system roles
    return false unless record.custom_role?
    true
  end

  # Delete custom role - Only Owner
  def destroy?
    return false unless user.owner?
    # Cannot delete system roles
    return false unless record.custom_role?
    # Authorization passes, but role service will handle business logic validation
    true
  end

  class Scope < Scope
    def resolve
      # For now, return all roles
      # When venue scoping is implemented:
      # scope.where(venue_id: user.venue_id).or(scope.where(is_custom: false))
      scope.all
    end
  end
end
