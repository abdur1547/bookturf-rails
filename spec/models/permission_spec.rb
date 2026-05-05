# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Permission, type: :model do
  describe 'associations' do
    it { should have_many(:role_permissions).dependent(:destroy) }
    it { should have_many(:roles).through(:role_permissions) }
  end

  describe 'validations' do
    subject { create(:permission, resource: 'bookings', action: 'create') }

    it { should validate_presence_of(:resource) }
    it { should validate_presence_of(:action) }
    it { should validate_uniqueness_of(:resource).scoped_to(:action) }

    it 'validates resource inclusion' do
      invalid = build(:permission, resource: 'invalid_resource', action: 'create')
      expect(invalid).not_to be_valid
      expect(invalid.errors[:resource]).to be_present
    end

    it 'validates action inclusion' do
      invalid = build(:permission, resource: 'bookings', action: 'invalid_action')
      expect(invalid).not_to be_valid
      expect(invalid.errors[:action]).to be_present
    end
  end

  describe 'scopes' do
    let!(:booking_create) { create(:permission, resource: 'bookings', action: 'create') }
    let!(:court_read) { create(:permission, resource: 'courts', action: 'read') }
    let!(:booking_read) { create(:permission, resource: 'bookings', action: 'read') }

    describe '.for_resource' do
      it 'returns permissions for the specified resource' do
        expect(Permission.for_resource('bookings')).to include(booking_create, booking_read)
        expect(Permission.for_resource('bookings')).not_to include(court_read)
      end
    end

    describe '.for_action' do
      it 'returns permissions for the specified action' do
        expect(Permission.for_action('read')).to include(court_read, booking_read)
        expect(Permission.for_action('read')).not_to include(booking_create)
      end
    end
  end
end
