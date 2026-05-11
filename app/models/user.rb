# frozen_string_literal: true

class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :refresh_tokens, dependent: :delete_all
  has_many :blacklisted_tokens, dependent: :delete_all
  has_many :password_reset_tokens, dependent: :delete_all

  has_many :venue_memberships, dependent: :destroy
  has_many :venues, through: :venue_memberships
  has_many :courts, through: :venues

  has_many :owned_venues, class_name: "Venue", foreign_key: "owner_id", dependent: :restrict_with_error

  has_many :bookings, dependent: :restrict_with_error
  has_many :created_bookings, class_name: "Booking", foreign_key: "created_by_id", dependent: :nullify
  has_many :cancelled_bookings, class_name: "Booking", foreign_key: "cancelled_by_id", dependent: :nullify
  has_many :checked_in_bookings, class_name: "Booking", foreign_key: "checked_in_by_id", dependent: :nullify
  has_many :notifications, dependent: :destroy

  has_secure_password

  enum :system_role, { normal: 0, super_admin: 1 }

  validates :full_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :phone_number, format: { with: /\A\+?[0-9\s\-()]+\z/, allow_blank: true }
  validates :emergency_contact_phone, format: { with: /\A\+?[0-9\s\-()]+\z/, allow_blank: true }

  normalizes :email, with: ->(e) { e.strip.downcase }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :super_admins, -> { where(system_role: :super_admin) }

  def owned_and_member_venues
    Venue.where("owner_id = :user_id OR id IN (SELECT venue_id FROM venue_memberships WHERE user_id = :user_id)", user_id: id)
  end

  def owned_and_member_courts
    Court.joins(:venue)
         .joins("LEFT OUTER JOIN venue_memberships ON venue_memberships.venue_id = venues.id")
         .where("venue_memberships.user_id = :user_id OR venues.owner_id = :user_id", user_id: id)
  end

  def self.from_omniauth(auth)
    data = auth.info
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = data.email
      user.password = SecureRandom.hex(20)
      name_parts = data.name.split(" ", 2)
      user.full_name = name_parts.join(" ") || "User full name"
      user.avatar_url = data.image
    end
  end

  def self.find_by_password_reset_token!(token)
    find_signed!(token, purpose: :password_reset)
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

  def has_permission?(venue:, resource:, action:)
    return true if super_admin?
    return true if venue.owner_id == id

    venue_memberships
      .joins(role: { role_permissions: :permission })
      .where(venue: venue)
      .where(permissions: { resource: resource, action: action })
      .exists?
  end
end
