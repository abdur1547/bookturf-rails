# frozen_string_literal: true

class CourtPolicy < ApplicationPolicy
  def index?
    true
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

    venue_owner? || user.super_admin?
  end

  private

  def venue_owner?
    return false unless record.is_a?(Court)

    record.venue.owner_id == user.id
  end
end
