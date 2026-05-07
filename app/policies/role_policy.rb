# frozen_string_literal: true

class RolePolicy < ApplicationPolicy
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

  class Scope < Scope
    def resolve
      return scope.none unless user.present?
      return scope.all if user.super_admin?

      scope.where(venue: user.owned_venues)
    end
  end

  private

  def have_permission?(action)
    venue = venue_from_record
    return false unless venue.is_a?(Venue)

    user.has_permission?(venue: venue, resource: "roles", action: action)
  end

  def venue_owner?
    venue = venue_from_record
    return false unless venue.is_a?(Venue)

    venue.owner_id == user.id
  end

  def venue_from_record
    case record
    when Role then record.venue
    when Venue then record
    end
  end
end
