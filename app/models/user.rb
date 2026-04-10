# frozen_string_literal: true

class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :refresh_tokens, dependent: :delete_all
  has_many :blacklisted_tokens, dependent: :delete_all
  has_many :password_reset_tokens, dependent: :delete_all
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  has_many :owned_venues, class_name: "Venue", foreign_key: "owner_id", dependent: :restrict_with_error

  has_many :venue_users, dependent: :destroy
  has_many :venues, through: :venue_users

  has_secure_password

  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :phone_number, format: { with: /\A\+?[0-9\s\-()]+\z/, allow_blank: true }
  validates :emergency_contact_phone, format: { with: /\A\+?[0-9\s\-()]+\z/, allow_blank: true }

  normalizes :email, with: ->(e) { e.strip.downcase }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :global_admins, -> { where(is_global_admin: true) }
  scope :owners, -> { joins(:roles).where(roles: { slug: "owner" }) }


  # For Google OAuth - create random password for OAuth users
  def self.from_omniauth(auth)
    data = auth.info
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = data.email
      user.password = SecureRandom.hex(20)
      # Split name into first and last name
      name_parts = data.name.split(" ", 2)
      user.first_name = name_parts[0] || "User"
      user.last_name = name_parts[1] || "Name"
      user.avatar_url = data.image
    end
  end

  # For password reset tokens
  def self.find_by_password_reset_token!(token)
    find_signed!(token, purpose: :password_reset)
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def activate!
    update(is_active: true)
  end

  def deactivate!
    update(is_active: false)
  end

  def generate_password_reset_token
    signed_id expires_in: 20.minutes, purpose: :password_reset
  end

  def assign_role(role, assigned_by: nil)
    user_roles.find_or_create_by!(role: role) do |ur|
      ur.assigned_by = assigned_by
    end
  end

  def remove_role(role)
    user_roles.find_by(role: role)&.destroy
  end

  def has_role?(role_name)
    roles.exists?(slug: role_name)
  end

  def has_permission?(permission_name)
    permissions.exists?(name: permission_name)
  end

  def permissions
    Permission.joins(roles: :users).where(users: { id: id }).distinct
  end

  def can?(action, resource)
    permission_name = "#{action}:#{resource}"
    has_permission?(permission_name) || has_permission?("manage:#{resource}")
  end

  def owner?
    has_role?("owner")
  end

  def admin?
    has_role?("admin")
  end

  def receptionist?
    has_role?("receptionist")
  end

  def staff?
    has_role?("staff")
  end

  def customer?
    has_role?("customer")
  end
end
