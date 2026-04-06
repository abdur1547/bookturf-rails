# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  # Example spec - ApplicationRecord is an abstract class
  # Individual model specs will inherit from this

  it 'is an abstract class' do
    expect(described_class.abstract_class?).to be true
  end
end
