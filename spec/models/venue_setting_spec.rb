require 'rails_helper'

RSpec.describe VenueSetting, type: :model do
  describe 'associations' do
    it { should belong_to(:venue) }
  end

  describe 'validations' do
    subject { build(:venue_setting) }

    it { should validate_presence_of(:minimum_slot_duration) }
    it { should validate_presence_of(:maximum_slot_duration) }
    it { should validate_presence_of(:slot_interval) }
    it { should validate_presence_of(:timezone) }
    it { should validate_presence_of(:currency) }

    it 'validates minimum_slot_duration is positive' do
      setting = build(:venue_setting, minimum_slot_duration: 0)
      expect(setting).not_to be_valid
      expect(setting.errors[:minimum_slot_duration]).to be_present
    end

    it 'validates maximum_slot_duration is positive' do
      setting = build(:venue_setting, maximum_slot_duration: 0)
      expect(setting).not_to be_valid
      expect(setting.errors[:maximum_slot_duration]).to be_present
    end

    it 'validates slot_interval is positive' do
      setting = build(:venue_setting, slot_interval: 0)
      expect(setting).not_to be_valid
      expect(setting.errors[:slot_interval]).to be_present
    end

    describe 'maximum_greater_than_minimum validation' do
      it 'is invalid when maximum is less than minimum' do
        setting = build(:venue_setting, minimum_slot_duration: 120, maximum_slot_duration: 60)
        expect(setting).not_to be_valid
        expect(setting.errors[:maximum_slot_duration]).to include('must be greater than or equal to minimum')
      end

      it 'is valid when maximum equals minimum' do
        setting = build(:venue_setting, minimum_slot_duration: 60, maximum_slot_duration: 60)
        expect(setting).to be_valid
      end

      it 'is valid when maximum is greater than minimum' do
        setting = build(:venue_setting, minimum_slot_duration: 60, maximum_slot_duration: 120)
        expect(setting).to be_valid
      end
    end
  end

  describe 'database constraints' do
    let(:venue) { create(:venue, :skip_callbacks) }

    it 'enforces minimum_slot_duration > 0 at database level' do
      setting = VenueSetting.new(
        venue: venue,
        minimum_slot_duration: 0,
        maximum_slot_duration: 180,
        slot_interval: 30,
        timezone: 'Asia/Karachi',
        currency: 'PKR'
      )
      expect {
        setting.save(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid, /minimum_slot_duration_positive/)
    end

    it 'enforces maximum_slot_duration >= minimum_slot_duration at database level' do
      setting = VenueSetting.new(
        venue: venue,
        minimum_slot_duration: 180,
        maximum_slot_duration: 60,
        slot_interval: 30,
        timezone: 'Asia/Karachi',
        currency: 'PKR'
      )
      expect {
        setting.save(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid, /maximum_greater_than_minimum/)
    end

    it 'enforces slot_interval > 0 at database level' do
      setting = VenueSetting.new(
        venue: venue,
        minimum_slot_duration: 60,
        maximum_slot_duration: 180,
        slot_interval: 0,
        timezone: 'Asia/Karachi',
        currency: 'PKR'
      )
      expect {
        setting.save(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid, /slot_interval_positive/)
    end
  end

  describe 'instance methods' do
    describe '#slot_durations' do
      it 'returns array of available slot durations' do
        setting = build(:venue_setting,
                       minimum_slot_duration: 60,
                       maximum_slot_duration: 180,
                       slot_interval: 30)
        expect(setting.slot_durations).to eq([ 60, 90, 120, 150, 180 ])
      end

      it 'returns single value when min equals max' do
        setting = build(:venue_setting,
                       minimum_slot_duration: 60,
                       maximum_slot_duration: 60,
                       slot_interval: 30)
        expect(setting.slot_durations).to eq([ 60 ])
      end

      it 'handles different intervals correctly' do
        setting = build(:venue_setting,
                       minimum_slot_duration: 30,
                       maximum_slot_duration: 90,
                       slot_interval: 15)
        expect(setting.slot_durations).to eq([ 30, 45, 60, 75, 90 ])
      end
    end
  end

  describe 'default values' do
    it 'has correct default for minimum_slot_duration' do
      venue = create(:venue, :skip_callbacks)
      setting = VenueSetting.new(venue: venue)
      expect(setting.minimum_slot_duration).to eq(60)
    end

    it 'has correct default for maximum_slot_duration' do
      venue = create(:venue, :skip_callbacks)
      setting = VenueSetting.new(venue: venue)
      expect(setting.maximum_slot_duration).to eq(180)
    end

    it 'has correct default for slot_interval' do
      venue = create(:venue, :skip_callbacks)
      setting = VenueSetting.new(venue: venue)
      expect(setting.slot_interval).to eq(30)
    end

    it 'has correct default for timezone' do
      venue = create(:venue, :skip_callbacks)
      setting = VenueSetting.new(venue: venue)
      expect(setting.timezone).to eq('Asia/Karachi')
    end

    it 'has correct default for currency' do
      venue = create(:venue, :skip_callbacks)
      setting = VenueSetting.new(venue: venue)
      expect(setting.currency).to eq('PKR')
    end

    it 'has correct default for advance_booking_days' do
      venue = create(:venue, :skip_callbacks)
      setting = VenueSetting.new(venue: venue)
      expect(setting.advance_booking_days).to eq(30)
    end

    it 'has correct default for requires_approval' do
      venue = create(:venue, :skip_callbacks)
      setting = VenueSetting.new(venue: venue)
      expect(setting.requires_approval).to be false
    end
  end
end
