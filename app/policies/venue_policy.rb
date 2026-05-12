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
    user.super_admin? || venue_owner? || have_permission?("update")
  end

  def destroy?
    user.super_admin? || venue_owner? || have_permission?("delete")
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
