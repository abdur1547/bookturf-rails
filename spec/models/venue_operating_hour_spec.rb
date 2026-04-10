require 'rails_helper'

RSpec.describe VenueOperatingHour, type: :model do
  describe 'associations' do
    it { should belong_to(:venue) }
  end

  describe 'validations' do
    subject { build(:venue_operating_hour) }

    it { should validate_presence_of(:day_of_week) }
    # it { should validate_uniqueness_of(:day_of_week).scoped_to(:venue_id) }

    it 'validates day_of_week is between 0 and 6' do
      hour = build(:venue_operating_hour, day_of_week: 7)
      expect(hour).not_to be_valid
      expect(hour.errors[:day_of_week]).to be_present
    end

    it 'validates opens_at presence when not closed' do
      hour = build(:venue_operating_hour, opens_at: nil, is_closed: false)
      expect(hour).not_to be_valid
      expect(hour.errors[:opens_at]).to be_present
    end

    it 'validates closes_at presence when not closed' do
      hour = build(:venue_operating_hour, closes_at: nil, is_closed: false)
      expect(hour).not_to be_valid
      expect(hour.errors[:closes_at]).to be_present
    end

    it 'allows nil opens_at when closed' do
      hour = build(:venue_operating_hour, :closed, opens_at: nil)
      expect(hour).to be_valid
    end

    it 'allows nil closes_at when closed' do
      hour = build(:venue_operating_hour, :closed, closes_at: nil)
      expect(hour).to be_valid
    end

    describe 'closes_after_opens validation' do
      it 'is invalid when closes_at is before opens_at' do
        hour = build(:venue_operating_hour, opens_at: '18:00', closes_at: '09:00')
        expect(hour).not_to be_valid
        expect(hour.errors[:closes_at]).to include('must be after opening time')
      end

      it 'is invalid when closes_at equals opens_at' do
        hour = build(:venue_operating_hour, opens_at: '09:00', closes_at: '09:00')
        expect(hour).not_to be_valid
        expect(hour.errors[:closes_at]).to include('must be after opening time')
      end

      it 'is valid when closes_at is after opens_at' do
        hour = build(:venue_operating_hour, opens_at: '09:00', closes_at: '23:00')
        expect(hour).to be_valid
      end

      it 'skips validation when is_closed is true' do
        hour = build(:venue_operating_hour, :closed, opens_at: '18:00', closes_at: '09:00')
        expect(hour).to be_valid
      end
    end
  end

  describe 'database constraints' do
    let(:venue) { create(:venue, :skip_callbacks) }

    it 'enforces day_of_week uniqueness per venue at database level' do
      create(:venue_operating_hour, venue: venue, day_of_week: 1)
      duplicate = VenueOperatingHour.new(venue: venue, day_of_week: 1, opens_at: '09:00', closes_at: '23:00')
      expect {
        duplicate.save(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows same day_of_week for different venues' do
      venue2 = create(:venue, :skip_callbacks)
      create(:venue_operating_hour, venue: venue, day_of_week: 1)
      expect {
        create(:venue_operating_hour, venue: venue2, day_of_week: 1)
      }.not_to raise_error
    end

    it 'enforces day_of_week range at database level' do
      hour = VenueOperatingHour.new(
        venue: venue,
        day_of_week: 7,
        opens_at: '09:00',
        closes_at: '23:00',
        is_closed: false
      )
      expect {
        hour.save(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid, /valid_day_of_week/)
    end
  end

  describe 'scopes' do
    let(:venue) { create(:venue, :skip_callbacks) }
    let!(:open_day) { create(:venue_operating_hour, venue: venue, day_of_week: 1, is_closed: false) }
    let!(:closed_day) { create(:venue_operating_hour, venue: venue, day_of_week: 2, is_closed: true) }

    describe '.open_days' do
      it 'returns only open days' do
        expect(VenueOperatingHour.open_days).to include(open_day)
        expect(VenueOperatingHour.open_days).not_to include(closed_day)
      end
    end

    describe '.closed_days' do
      it 'returns only closed days' do
        expect(VenueOperatingHour.closed_days).to include(closed_day)
        expect(VenueOperatingHour.closed_days).not_to include(open_day)
      end
    end
  end

  describe 'instance methods' do
    describe '#day_name' do
      it 'returns Sunday for day 0' do
        hour = build(:venue_operating_hour, :sunday)
        expect(hour.day_name).to eq('Sunday')
      end

      it 'returns Monday for day 1' do
        hour = build(:venue_operating_hour, :monday)
        expect(hour.day_name).to eq('Monday')
      end

      it 'returns Tuesday for day 2' do
        hour = build(:venue_operating_hour, :tuesday)
        expect(hour.day_name).to eq('Tuesday')
      end

      it 'returns Wednesday for day 3' do
        hour = build(:venue_operating_hour, :wednesday)
        expect(hour.day_name).to eq('Wednesday')
      end

      it 'returns Thursday for day 4' do
        hour = build(:venue_operating_hour, :thursday)
        expect(hour.day_name).to eq('Thursday')
      end

      it 'returns Friday for day 5' do
        hour = build(:venue_operating_hour, :friday)
        expect(hour.day_name).to eq('Friday')
      end

      it 'returns Saturday for day 6' do
        hour = build(:venue_operating_hour, :saturday)
        expect(hour.day_name).to eq('Saturday')
      end
    end

    describe '#formatted_hours' do
      it 'returns Closed when is_closed is true' do
        hour = build(:venue_operating_hour, :closed)
        expect(hour.formatted_hours).to eq('Closed')
      end

      it 'returns formatted time range when open' do
        hour = build(:venue_operating_hour, opens_at: '09:00', closes_at: '23:00')
        expect(hour.formatted_hours).to eq('09:00 AM - 11:00 PM')
      end

      it 'handles midnight correctly' do
        hour = build(:venue_operating_hour, opens_at: '08:00', closes_at: '00:00')
        expect(hour.formatted_hours).to eq('08:00 AM - 12:00 AM')
      end
    end
  end

  describe 'DAYS_OF_WEEK constant' do
    it 'has correct mapping' do
      expect(VenueOperatingHour::DAYS_OF_WEEK).to eq({
        0 => 'Sunday',
        1 => 'Monday',
        2 => 'Tuesday',
        3 => 'Wednesday',
        4 => 'Thursday',
        5 => 'Friday',
        6 => 'Saturday'
      })
    end
  end
end
