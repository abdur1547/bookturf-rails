# frozen_string_literal: true

class VenueMembership < ApplicationRecord
  belongs_to :user
  belongs_to :venue
  belongs_to :role

  validates :user_id, uniqueness: { scope: :venue_id }
end
