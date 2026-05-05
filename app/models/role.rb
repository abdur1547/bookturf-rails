# frozen_string_literal: true

class Role < ApplicationRecord
  belongs_to :venue

  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  has_many :venue_memberships, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { scope: :venue_id }

  scope :alphabetical, -> { order(:name) }

  def add_permission(permission)
    permissions << permission unless permissions.include?(permission)
  end

  def remove_permission(permission)
    permissions.delete(permission)
  end
end
