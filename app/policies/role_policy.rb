# frozen_string_literal: true

class RolePolicy < ApplicationPolicy
  def index?
    user.present? && (user.super_admin? || user.owned_venues.any?)
  end

  def show?
    user.present? && (user.super_admin? || venue_owner?)
  end

  def create?
    user.present? && (user.super_admin? || user.owned_venues.any?)
  end

  def update?
    user.present? && (user.super_admin? || venue_owner?)
  end

  def destroy?
    user.present? && (user.super_admin? || venue_owner?)
  end

  class Scope < Scope
    def resolve
      return scope.none unless user.present?
      return scope.all if user.super_admin?

      scope.where(venue: user.owned_venues)
    end
  end

  private

  def venue_owner?
    return false unless record.is_a?(Role)

    record.venue.owner_id == user.id
  end
end
