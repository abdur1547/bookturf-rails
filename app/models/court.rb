class Court < ApplicationRecord
  belongs_to :venue
  belongs_to :court_type

  has_many :pricing_rules, dependent: :destroy
  # TODO: think how to handle bookings when court is deleted. Should we delete them or prevent deletion if there are active bookings?
  has_many :bookings, dependent: :destroy
  has_many :court_closures, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :venue_id }
  validates :slot_interval, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :of_type, ->(court_type) { where(court_type: court_type) }

  def sport_name
    court_type.name
  end

  def full_name
    "#{name} (#{sport_name})"
  end

  def activate!
    update(is_active: true)
  end

  def deactivate!
    update(is_active: false)
  end

  # Image handling - Shrine JSONB array
  def images_array
    images_data.is_a?(Array) ? images_data : []
  end

  def add_image(image_data)
    current_images = images_array
    current_images << image_data
    update(images_data: current_images)
  end

  def remove_image(image_index)
    current_images = images_array
    current_images.delete_at(image_index)
    update(images_data: current_images)
  end

  def primary_image
    images_array.first
  end

  def has_images?
    images_array.present?
  end

  def generate_qr_code_url
    update(qr_code_url: "https://example.com/qr/court-#{id}-#{Time.current.to_i}.png")
  end

  def has_qr_code?
    qr_code_url.present?
  end

  def court_type_name
    court_type&.name
  end

  def venue_name
    venue&.name
  end

  def price_range
    prices = pricing_rules.map(&:price_per_hour)
    { min: (prices.min || 0).to_f, max: (prices.max || 0).to_f }
  end

  def available_at?(start_time, end_time)
    return false unless is_active?
    return false if CourtClosure.court_closed?(self, start_time, end_time)
    return false unless Booking.slot_available?(self, start_time, end_time)
    true
  end
end
