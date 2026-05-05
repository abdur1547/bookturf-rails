# frozen_string_literal: true

class BookingPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return false unless user.present?
    return true if user.super_admin? || venue_owner?

    staff_have_permission?("read") || own_booking?
  end

  def create?
    user.present?
  end

  def update?
    return false unless user.present?
    return true if user.super_admin? || venue_owner?

    staff_have_permission?("update") || own_booking?
  end

  def destroy?
    return false unless user.present?
    return true if user.super_admin? || venue_owner?

    staff_have_permission?("manage") || own_booking?
  end

  def cancel?
    return false unless user.present?
    return true if user.super_admin? || venue_owner?

    staff_have_permission?("manage") || own_booking?
  end

  def check_in?
    return false unless user.present?
    return true if user.super_admin? || venue_owner?

    staff_have_permission?("manage")
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

    staff_have_permission?("update") || own_booking?
  end

  private

  def staff_have_permission?(action)
    venue_staff? && have_permission?(action)
  end

  def venue_staff?
    return false unless record.is_a?(Booking)

    venue.venue_memberships.exists?(user_id: user.id)
  end

  def have_permission?(action)
    user.has_permission?(venue: venue, resource: "bookings", action: action)
  end

  def venue_owner?
    return false unless record.is_a?(Booking)

    venue.owner_id == user.id
  end

  def own_booking?
    return false unless record.is_a?(Booking)

    record.user_id == user.id
  end

  def venue
    @venue ||= record.venue
  end
end
