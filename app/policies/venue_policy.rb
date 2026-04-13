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

    # Owner or Global Admin can update
    owner? || global_admin?
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

  def global_admin?
    user.admin?
  end
end
