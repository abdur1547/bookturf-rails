# frozen_string_literal: true

class StaffPolicy < ApplicationPolicy
  def index?
    user.present? && (user.super_admin? || venue_owner? || have_permission?("read"))
  end

  def show?
    user.present? && (user.super_admin? || venue_owner? || have_permission?("read"))
  end

  def create?
    user.present? && (user.super_admin? || venue_owner? || have_permission?("create"))
  end

  def update?
    user.present? && (user.super_admin? || venue_owner? || have_permission?("update"))
  end

  def destroy?
    user.present? && (user.super_admin? || venue_owner? || have_permission?("delete"))
  end

  private

  def have_permission?(action)
    return false unless record.is_a?(Venue)

    user.has_permission?(venue: record, resource: "users", action: action)
  end

  def venue_owner?
    return false unless record.is_a?(Venue)

    record.owner_id == user.id
  end
end
