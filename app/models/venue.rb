class Venue < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: "owner_id"

  has_one :venue_setting, dependent: :destroy
  has_many :venue_operating_hours, -> { order(:day_of_week) }, dependent: :destroy
  has_many :venue_users, dependent: :destroy
  has_many :staff_members, through: :venue_users, source: :user

  # Accept nested attributes for settings and hours
  accepts_nested_attributes_for :venue_setting
  accepts_nested_attributes_for :venue_operating_hours, allow_destroy: true

  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers, and hyphens" }
  validates :address, presence: true
  validates :phone_number, format: { with: /\A\+?[0-9\s\-()]+\z/, allow_blank: true }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true

  # One venue per owner (MVP constraint)
  validate :owner_can_have_only_one_venue, on: :create

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  after_create :create_default_settings
  after_create :create_default_operating_hours

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

  def to_param
    slug
  end

  private

  def generate_slug
    base_slug = name.parameterize
    slug_candidate = base_slug
    counter = 2

    # Handle slug conflicts by adding a counter
    while Venue.exists?(slug: slug_candidate)
      slug_candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = slug_candidate
  end

  def create_default_settings
    create_venue_setting! unless venue_setting.present?
  end

  def create_default_operating_hours
    return if venue_operating_hours.any?

    # Create default hours: Monday-Sunday, 9 AM - 11 PM
    (0..6).each do |day|
      venue_operating_hours.create!(
        day_of_week: day,
        opens_at: "09:00",
        closes_at: "23:00",
        is_closed: false
      )
    end
  end

  def owner_can_have_only_one_venue
    if owner && owner.owned_venues.exists?
      errors.add(:owner, "can only own one venue in MVP")
    end
  end
end
