# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  # Example controller spec
  # Add shared controller behavior tests here

  it 'inherits from ActionController::Base' do
    expect(described_class.superclass).to eq(ActionController::Base)
  end
end
