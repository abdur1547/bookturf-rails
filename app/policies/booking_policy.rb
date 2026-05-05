# frozen_string_literal: true

class BookingPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return false unless user.present?
    return true if user.super_admin? || venue_owner?

    user.has_permission?(venue: record.venue, resource: "bookings", action: "read") ||
      record.user_id == user.id
  end

  def create?
    user.present?
  end

  def update?
    return false unless user.present?
    return true if user.super_admin? || venue_owner?

    user.has_permission?(venue: record.venue, resource: "bookings", action: "update") ||
      record.user_id == user.id
  end

  def destroy?
    return false unless user.present?
    return true if user.super_admin? || venue_owner?

    user.has_permission?(venue: record.venue, resource: "bookings", action: "manage") ||
      record.user_id == user.id
  end

  def cancel?
    return false unless user.present?
    return true if user.super_admin? || venue_owner?

    user.has_permission?(venue: record.venue, resource: "bookings", action: "manage") ||
      record.user_id == user.id
  end

  def check_in?
    return false unless user.present?
    return true if user.super_admin? || venue_owner?

    user.has_permission?(venue: record.venue, resource: "bookings", action: "manage")
  end

  def mark_no_show?
    check_in?
  end

  def complete?
    check_in?
  end

  def reschedule?
    return false unless user.present?
    return true if user.super_admin? || venue_owner?

    user.has_permission?(venue: record.venue, resource: "bookings", action: "update") ||
      record.user_id == user.id
  end

  private

  def venue_owner?
    record.is_a?(Booking) && record.venue.owner_id == user.id
  end
end
