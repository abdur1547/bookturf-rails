# frozen_string_literal: true

class VenuePolicy < ApplicationPolicy
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

    owner? || user.super_admin?
  end

  def destroy?
    return false unless user.present?

    owner?
  end

  private

  def owner?
    record.owner_id == user.id
  end
end
