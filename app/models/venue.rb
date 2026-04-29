class Venue < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: "owner_id"

  has_many :venue_operating_hours, -> { order(:day_of_week) }, dependent: :destroy
  has_many :venue_closures, dependent: :destroy
  has_many :venue_users, dependent: :destroy
  has_many :staff_members, through: :venue_users, source: :user
  has_many :courts, dependent: :destroy
  has_many :pricing_rules, dependent: :destroy
  has_many :bookings, dependent: :restrict_with_error
  has_many :court_closures, dependent: :destroy
  has_many :notifications, dependent: :destroy

  accepts_nested_attributes_for :venue_operating_hours, allow_destroy: true

  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers, and hyphens" }
  validates :address, presence: true
  validates :phone_number, format: { with: /\A\+?[0-9\s\-()]+\z/, allow_blank: true }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validates :timezone, presence: true
  validates :currency, presence: true

  # One venue per owner (MVP constraint)
  validate :owner_can_have_only_one_venue, on: :create

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :in_city, ->(city) { where(city: city) }

  def google_maps_url
    return nil unless latitude.present? && longitude.present?
    "https://www.google.com/maps?q=#{latitude},#{longitude}"
  end

  def activate!
    update(is_active: true)
  end

  def deactivate!
    update(is_active: false)
  end

  def operating_hours_for(day_of_week)
    venue_operating_hours.find_by(day_of_week: day_of_week)
  end

  def open_on?(day_of_week)
    hours = operating_hours_for(day_of_week)
    hours.present? && !hours.is_closed
  end

  def closed_on?(date)
    venue_closures.overlapping(date.beginning_of_day, date.end_of_day).exists?
  end

  private

  def generate_slug
    base_slug = name.parameterize
    slug_candidate = base_slug
    counter = 2

    while Venue.exists?(slug: slug_candidate)
      slug_candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = slug_candidate
  end

  def owner_can_have_only_one_venue
    return unless owner_id

    query = Venue.where(owner_id: owner_id)
    query = query.where.not(id: id) if persisted?

    if query.exists?
      errors.add(:owner, "can only own one venue in MVP")
    end
  end
end
