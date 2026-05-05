# frozen_string_literal: true

class Permission < ApplicationRecord
  ACTIONS = %w[create read update delete manage].freeze

  RESOURCES = %w[
    bookings courts venues users roles reports settings
    pricing closures notifications
  ].freeze

  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :resource, presence: true, inclusion: { in: RESOURCES }
  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :resource, uniqueness: { scope: :action }

  scope :for_resource, ->(resource) { where(resource: resource) }
  scope :for_action, ->(action) { where(action: action) }
end
