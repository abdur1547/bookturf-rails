# frozen_string_literal: true

class VenuePolicy < ApplicationPolicy
  def index?
    true # Public endpoint - anyone can list venues
  end

  def show?
    true # Public endpoint - anyone can view venue details
  end

  def create?
    user.present? # Any authenticated user can create a venue
  end

  def update?
    return false unless user.present?

    # Owner or Admin can update
    owner? || admin?
  end

  def destroy?
    return false unless user.present?

    # Only owner can delete
    owner?
  end

  private

  def owner?
    record.owner_id == user.id
  end

  def admin?
    # Check if user has admin role for this venue
    user.venue_users.exists?(venue_id: record.id, role: "admin")
  end
end
