class VenueUser < ApplicationRecord
  belongs_to :venue
  belongs_to :user
  belongs_to :added_by, class_name: "User", optional: true

  validates :user_id, uniqueness: { scope: :venue_id, message: "is already a staff member at this venue" }
  validates :joined_at, presence: true

  before_validation :set_joined_at, on: :create

  scope :recent, -> { order(joined_at: :desc) }

  private

  def set_joined_at
    self.joined_at ||= Time.current
  end
end
