# frozen_string_literal: true

class VenuePolicy < ApplicationPolicy
  def index?
    user.super_admin? || venue_owner? || have_permission?("read")
  end

  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    return false unless user.present?

    venue_owner? || user.super_admin?
  end

  def destroy?
    return false unless user.present?

    venue_owner?
  end

  private

  def have_permission?(action)
    user.has_permission?(venue: record, resource: "venues", action: action)
  end

  def venue_owner?
    return false unless record.is_a?(Venue)

    record.owner_id == user.id
  end
end
