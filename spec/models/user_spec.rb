require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:refresh_tokens).dependent(:delete_all) }
    it { should have_many(:blacklisted_tokens).dependent(:delete_all) }
    it { should have_many(:password_reset_tokens).dependent(:delete_all) }
    it { should have_many(:venue_memberships).dependent(:destroy) }
    it { should have_many(:venues).through(:venue_memberships) }
    it { should have_many(:owned_venues).class_name('Venue').with_foreign_key('owner_id').dependent(:restrict_with_error) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:full_name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }

    it 'validates full_name length' do
      user = build(:user, full_name: 'a')
      expect(user).not_to be_valid
      expect(user.errors[:full_name]).to include('is too short (minimum is 2 characters)')
    end

    it 'validates full_name maximum length' do
      user = build(:user, full_name: 'a' * 101)
      expect(user).not_to be_valid
      expect(user.errors[:full_name]).to include('is too long (maximum is 100 characters)')
    end

    it 'validates phone number format' do
      user = build(:user, phone_number: 'invalid')
      expect(user).not_to be_valid
      expect(user.errors[:phone_number]).to be_present
    end

    it 'allows valid phone number' do
      user = build(:user, phone_number: '+92 300 1234567')
      expect(user).to be_valid
    end
  end

  describe 'enum :system_role' do
    it 'defaults to normal' do
      user = create(:user)
      expect(user.system_role).to eq('normal')
      expect(user.normal?).to be true
      expect(user.super_admin?).to be false
    end

    it 'can be set to super_admin' do
      user = create(:user, :super_admin)
      expect(user.super_admin?).to be true
    end
  end

  describe 'scopes' do
    let!(:active_user) { create(:user, is_active: true) }
    let!(:inactive_user) { create(:user, :inactive) }
    let!(:admin_user) { create(:user, :super_admin) }

    describe '.active' do
      it 'returns only active users' do
        expect(User.active).to include(active_user, admin_user)
        expect(User.active).not_to include(inactive_user)
      end
    end

    describe '.inactive' do
      it 'returns only inactive users' do
        expect(User.inactive).to include(inactive_user)
        expect(User.inactive).not_to include(active_user)
      end
    end

    describe '.super_admins' do
      it 'returns only super admins' do
        expect(User.super_admins).to include(admin_user)
        expect(User.super_admins).not_to include(active_user, inactive_user)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }

    describe '#activate!' do
      it 'sets is_active to true' do
        user.update(is_active: false)
        expect { user.activate! }.to change { user.is_active }.from(false).to(true)
      end
    end

    describe '#deactivate!' do
      it 'sets is_active to false' do
        expect { user.deactivate! }.to change { user.is_active }.from(true).to(false)
      end
    end
  end

  describe '#has_permission?' do
    let(:user) { create(:user) }
    let(:venue) { create(:venue) }
    let(:role) { create(:role, venue: venue) }
    let(:permission) { create(:permission, :create_bookings) }

    context 'when user is super_admin' do
      let(:user) { create(:user, :super_admin) }

      it 'returns true regardless of venue or permission' do
        expect(user.has_permission?(venue: venue, resource: 'bookings', action: 'create')).to be true
      end
    end

    context 'when user is venue owner' do
      let(:venue) { create(:venue, owner: user) }

      it 'returns true' do
        expect(user.has_permission?(venue: venue, resource: 'bookings', action: 'create')).to be true
      end
    end

    context 'when user has a venue membership with the permission' do
      before do
        role.add_permission(permission)
        create(:venue_membership, user: user, venue: venue, role: role)
      end

      it 'returns true' do
        expect(user.has_permission?(venue: venue, resource: 'bookings', action: 'create')).to be true
      end

      it 'returns false for a different action' do
        expect(user.has_permission?(venue: venue, resource: 'bookings', action: 'delete')).to be false
      end
    end

    context 'when user has no membership at the venue' do
      it 'returns false' do
        expect(user.has_permission?(venue: venue, resource: 'bookings', action: 'create')).to be false
      end
    end
  end
end
