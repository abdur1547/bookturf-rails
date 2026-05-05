# frozen_string_literal: true

class PricingRulePolicy < ApplicationPolicy
  def index?
    user.present? && (user.super_admin? || venue_owner? || staff_have_permission?("read"))
  end

  def show?
    index?
  end

  def create?
    user.present? && (user.super_admin? || venue_owner? || staff_have_permission?("create"))
  end

  def update?
    user.present? && (user.super_admin? || venue_owner? || staff_have_permission?("update"))
  end

  def destroy?
    user.present? && (user.super_admin? || venue_owner? || staff_have_permission?("delete"))
  end

  class Scope < Scope
    def resolve
      return scope.none unless user.present?
      return scope.all if user.super_admin?

      scope.where(venue: user.owned_venues).or(scope.where(venue: user.venues))
    end
  end

  private

  def staff_have_permission?(action)
    venue_staff? && have_permission?(action)
  end

  def venue_staff?
    return false unless record.is_a?(PricingRule)

    venue.venue_memberships.exists?(user_id: user.id)
  end

  def have_permission?(action)
    user.has_permission?(venue: venue, resource: "pricing", action: action)
  end

  def venue_owner?
    return false unless record.is_a?(PricingRule)

    venue.owner_id == user.id
  end

  def venue
    @venue ||= record.venue
  end
end
