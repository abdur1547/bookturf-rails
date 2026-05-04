class CourtType < ApplicationRecord
  has_many :courts, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers, and hyphens" }

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :alphabetical, -> { order(:name) }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
