# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'associations' do
    it { should belong_to(:venue) }
    it { should have_many(:role_permissions).dependent(:destroy) }
    it { should have_many(:permissions).through(:role_permissions) }
    it { should have_many(:venue_memberships) }
  end

  describe 'validations' do
    subject { build(:role) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:venue_id) }
  end

  describe 'scopes' do
    describe '.alphabetical' do
      let(:venue) { create(:venue) }
      let!(:role_z) { create(:role, name: 'Zebra', venue: venue) }
      let!(:role_a) { create(:role, name: 'Alpha', venue: venue) }

      it 'returns roles in alphabetical order' do
        expect(Role.alphabetical.first).to eq(role_a)
        expect(Role.alphabetical.last).to eq(role_z)
      end
    end
  end

  describe '#add_permission' do
    let(:role) { create(:role) }
    let(:permission) { create(:permission, :create_bookings) }

    it 'adds permission to role' do
      expect { role.add_permission(permission) }
        .to change { role.permissions.count }.by(1)
    end

    it 'does not duplicate permission' do
      role.add_permission(permission)
      expect { role.add_permission(permission) }
        .not_to change { role.permissions.count }
    end
  end

  describe '#remove_permission' do
    let(:role) { create(:role) }
    let(:permission) { create(:permission, :create_bookings) }

    before { role.add_permission(permission) }

    it 'removes permission from role' do
      expect { role.remove_permission(permission) }
        .to change { role.permissions.count }.by(-1)
    end
  end
end
