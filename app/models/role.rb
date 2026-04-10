# frozen_string_literal: true

class Role < ApplicationRecord
  SYSTEM_ROLES = %w[owner admin receptionist staff customer].freeze

  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :name, presence: true, uniqueness: true
  validates :slug, uniqueness: true, allow_blank: true
  validates :slug, format: { with: /\A[a-z0-9\-_]+\z/, message: "only lowercase letters, numbers, hyphens, and underscores" }, allow_blank: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  before_update :regenerate_slug_on_name_change, if: -> { name_changed? && persisted? }
  before_destroy :prevent_system_role_deletion

  scope :system_roles, -> { where(is_custom: false) }
  scope :custom_roles, -> { where(is_custom: true) }
  scope :alphabetical, -> { order(:name) }

  def self.find_by_slug!(slug)
    find_by!(slug: slug)
  end

  def system_role?
    !is_custom
  end

  def custom_role?
    is_custom
  end

  def add_permission(permission)
    permissions << permission unless permissions.include?(permission)
  end

  def remove_permission(permission)
    permissions.delete(permission)
  end

  def has_permission?(permission_name)
    permissions.exists?(name: permission_name)
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize(separator: "_")
  end

  def regenerate_slug_on_name_change
    generate_slug
  end

  def prevent_system_role_deletion
    if system_role?
      errors.add(:base, "System roles cannot be deleted")
      throw(:abort)
    end
  end
end
