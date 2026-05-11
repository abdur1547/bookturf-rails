# frozen_string_literal: true

class CourtPolicy < ApplicationPolicy
  def index?
    return false unless user.present?

    user.super_admin? || venue_owner? || staff_have_permission?("read")
  end

  def show?
    index?
  end

  def create?
    user.present?
  end

  def update?
    return false unless user.present?

    user.super_admin? || venue_owner? || staff_have_permission?("update")
  end

  def destroy?
    return false unless user.present?

    user.super_admin? || venue_owner? || staff_have_permission?("delete")
  end

  private

  def staff_have_permission?(action)
    venue_staff? && have_permission?(action)
  end

  def venue_staff?
    return false unless record.is_a?(Court)

    venue.venue_memberships.exists?(user_id: user.id)
  end

  def have_permission?(action)
    user.has_permission?(venue: venue, resource: "courts", action: action)
  end

  def venue_owner?
    return false unless record.is_a?(Court)

    venue.owner_id == user.id
  end

  def venue
    @venue ||= record.venue
  end
end
