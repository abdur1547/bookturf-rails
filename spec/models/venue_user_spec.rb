require 'rails_helper'

RSpec.describe VenueUser, type: :model do
  describe 'associations' do
    it { should belong_to(:venue) }
    it { should belong_to(:user) }
    it { should belong_to(:added_by).class_name('User').optional }
  end

  describe 'validations' do
    subject { build(:venue_user) }

    # Joined_at is set by callback, not validated directly
    # it { should validate_presence_of(:joined_at) }

    describe 'user_id uniqueness per venue' do
      let(:venue) { create(:venue, :skip_callbacks) }
      let(:user) { create(:user) }

      it 'prevents duplicate user assignment to same venue' do
        create(:venue_user, venue: venue, user: user)
        duplicate = build(:venue_user, venue: venue, user: user)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to include('is already a staff member at this venue')
      end

      it 'allows same user at different venues' do
        venue2 = create(:venue, :skip_callbacks)
        create(:venue_user, venue: venue, user: user)
        expect {
          create(:venue_user, venue: venue2, user: user)
        }.not_to raise_error
      end
    end
  end

  describe 'database constraints' do
    let(:venue) { create(:venue, :skip_callbacks) }
    let(:user) { create(:user) }

    it 'enforces unique venue_id and user_id combination at database level' do
      create(:venue_user, venue: venue, user: user)
      duplicate = VenueUser.new(venue: venue, user: user, joined_at: Time.current)
      expect {
        duplicate.save(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'callbacks' do
    describe 'set_joined_at' do
      it 'sets joined_at on creation if not provided' do
        venue_user = create(:venue_user, joined_at: nil)
        expect(venue_user.joined_at).to be_present
        expect(venue_user.joined_at).to be_within(1.second).of(Time.current)
      end

      it 'does not override manually set joined_at' do
        past_time = 1.month.ago
        venue_user = create(:venue_user, joined_at: past_time)
        expect(venue_user.joined_at).to be_within(1.second).of(past_time)
      end
    end
  end

  describe 'scopes' do
    let(:venue) { create(:venue, :skip_callbacks) }
    let!(:recent_staff) { create(:venue_user, venue: venue, joined_at: 1.day.ago) }
    let!(:old_staff) { create(:venue_user, venue: venue, joined_at: 1.year.ago) }

    describe '.recent' do
      it 'orders by joined_at descending' do
        expect(VenueUser.recent.first).to eq(recent_staff)
        expect(VenueUser.recent.last).to eq(old_staff)
      end
    end
  end

  describe 'staff member flow' do
    let(:owner) { create(:user) }
    let(:venue) { create(:venue, owner: owner) }
    let(:staff) { create(:user) }

    it 'allows adding staff member to venue' do
      expect {
        VenueUser.create!(
          venue: venue,
          user: staff,
          added_by: owner
        )
      }.to change { venue.staff_members.count }.by(1)
    end

    it 'tracks who added the staff member' do
      venue_user = VenueUser.create!(
        venue: venue,
        user: staff,
        added_by: owner
      )
      expect(venue_user.added_by).to eq(owner)
    end

    it 'allows staff member without specifying who added them' do
      venue_user = VenueUser.create!(
        venue: venue,
        user: staff
      )
      expect(venue_user.added_by).to be_nil
    end
  end

  describe 'integration with User and Venue' do
    let(:owner) { create(:user) }
    let(:venue) { create(:venue, owner: owner) }
    let(:staff1) { create(:user) }
    let(:staff2) { create(:user) }

    before do
      create(:venue_user, venue: venue, user: staff1)
      create(:venue_user, venue: venue, user: staff2)
    end

    it 'venue has access to staff members through association' do
      expect(venue.staff_members).to include(staff1, staff2)
      expect(venue.staff_members.count).to eq(2)
    end

    it 'user has access to venues through association' do
      expect(staff1.venues).to include(venue)
    end

    it 'removing venue_user removes association but not entities' do
      venue_user = VenueUser.find_by(venue: venue, user: staff1)
      venue_user.destroy

      expect(venue.reload.staff_members).not_to include(staff1)
      expect(staff1.reload).to be_present # User still exists
      expect(venue.reload).to be_present # Venue still exists
    end
  end
end
