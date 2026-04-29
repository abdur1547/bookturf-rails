# # frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe 'API V0 Venue Availability', type: :request do
#   let(:headers) { { 'Content-Type' => 'application/json' } }

#   let(:owner_user) { create(:user, :owner, email: 'owner@example.com') }
#   let(:customer_user) { create(:user, :customer, email: 'customer@example.com') }
#   let(:venue) do
#     create(:venue, :with_setting, :with_operating_hours, owner: owner_user)
#   end
#   let(:court_type) { create(:court_type, name: 'Badminton') }
#   let(:court) { create(:court, venue: venue, court_type: court_type) }
#   let(:minimum_slot_duration) { venue.venue_setting.minimum_slot_duration }
#   let(:slot_date) { Date.current + 3 }
#   let(:start_date) { slot_date.strftime('%Y-%m-%d') }
#   let(:endpoint) { "/api/v0/venues/#{venue.id}/availability" }

#   before do
#     create(:pricing_rule,
#            venue: venue,
#            court_type: court_type,
#            name: 'Standard Rate',
#            price_per_hour: 1200,
#            priority: 1,
#            is_active: true)
#   end

#   describe 'GET /api/v0/venues/:id/availability' do
#     context 'when requesting available slots' do
#       before do
#         get endpoint,
#             params: {
#               start_date: start_date,
#               duration_minutes: minimum_slot_duration,
#               court_id: court.id
#             },
#             headers: headers
#       end

#       it 'returns a successful response' do
#         expect(response).to have_http_status(:ok)
#         expect(response.parsed_body['success']).to be true
#       end

#       it 'returns court availability with at least one slot' do
#         data = response.parsed_body['data']
#         expect(data['venue_id']).to eq(venue.id)
#         expect(data['court_availability']).to be_an(Array)
#         expect(data['court_availability'].first['court_id']).to eq(court.id)
#         expect(data['court_availability'].first['slots']).to be_an(Array)
#         expect(data['court_availability'].first['slots']).not_to be_empty
#       end

#       it 'includes pricing and availability flags for each slot' do
#         slot = response.parsed_body['data']['court_availability'].first['slots'].first
#         expect(slot['start_time']).to eq(Time.find_zone(venue.venue_setting.timezone).local(slot_date.year, slot_date.month, slot_date.day, 9, 0).iso8601)
#         expect(slot['duration_minutes']).to eq(minimum_slot_duration)
#         expect(slot['price_per_hour']).to eq('1200.0')
#         expect(slot['total_amount']).to eq('1200.0')
#         expect(slot['available']).to be(true)
#         expect(slot['booked']).to be(false)
#         expect(slot['booking_status']).to be_nil
#       end
#     end

#     context 'when the slot overlaps a confirmed booking' do
#       let(:booking_start) do
#         Time.find_zone(venue.venue_setting.timezone).local(slot_date.year, slot_date.month, slot_date.day, 10, 0)
#       end
#       let(:booking_end) { booking_start + minimum_slot_duration.minutes }

#       before do
#         create(:booking,
#                court: court,
#                venue: venue,
#                user: customer_user,
#                start_time: booking_start,
#                end_time: booking_end,
#                duration_minutes: minimum_slot_duration,
#                status: 'confirmed')
#       end

#       it 'does not include the booked slot by default' do
#         get endpoint,
#             params: {
#               start_date: start_date,
#               duration_minutes: minimum_slot_duration,
#               court_id: court.id
#             },
#             headers: headers

#         slots = response.parsed_body['data']['court_availability'].first['slots']
#         expect(slots).to all(include('available' => true))
#         expect(slots).to all(include('booked' => false))
#       end

#       it 'includes booked slots when include_booked is true' do
#         get endpoint,
#             params: {
#               start_date: start_date,
#               duration_minutes: minimum_slot_duration,
#               court_id: court.id,
#               include_booked: true
#             },
#             headers: headers

#         slots = response.parsed_body['data']['court_availability'].first['slots']
#         expect(slots).to include(include('booked' => true, 'booking_status' => 'confirmed'))
#       end
#     end
#   end
# end
