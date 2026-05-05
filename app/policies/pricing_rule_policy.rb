# frozen_string_literal: true

class PricingRulePolicy < ApplicationPolicy
  def index?
    user.present? && (user.super_admin? || venue_owner?)
  end

  def show?
    index?
  end

  def create?
    user.present? && (user.super_admin? || venue_owner?)
  end

  def update?
    create?
  end

  def destroy?
    create?
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
    return false unless record.is_a?(PricingRule)

    record.venue.owner_id == user.id
  end
end
