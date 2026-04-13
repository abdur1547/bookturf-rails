class Court < ApplicationRecord
  belongs_to :venue
  belongs_to :court_type

  has_many :bookings, dependent: :restrict_with_error
  has_many :court_closures, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :venue_id }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :by_display_order, -> { order(:display_order, :name) }
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

  # Check if court is available at a specific time
  def available_at?(start_time, end_time)
    return false unless is_active?

    # Check closures
    return false if CourtClosure.court_closed?(self, start_time, end_time)

    # Check bookings
    return false unless Booking.slot_available?(self, start_time, end_time)

    true
  end
end
