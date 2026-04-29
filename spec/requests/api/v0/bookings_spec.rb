# # frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe 'API V0 Bookings', type: :request do
#   let(:headers) { { 'Content-Type' => 'application/json' } }

#   let(:owner_user) { create(:user, :owner, email: 'owner@example.com') }
#   let(:customer_user) { create(:user, :customer, email: 'customer@example.com') }

#   let(:venue) do
#     create(:venue, :with_setting, :with_operating_hours, owner: owner_user)
#   end

#   let(:court_type) { create(:court_type, name: 'Badminton') }
#   let(:court) { create(:court, venue: venue, court_type: court_type) }

#   before do
#     create(:venue_user, venue: venue, user: customer_user, added_by: owner_user)
#     create(:pricing_rule,
#            venue: venue,
#            court_type: court_type,
#            name: 'Standard Rate',
#            price_per_hour: 1200,
#            priority: 1,
#            is_active: true)
#   end

#   describe 'POST /api/v0/bookings' do
#     let(:request_headers) { headers.merge(auth_headers(auth_token_for(customer_user))) }
#     let(:start_time) { 2.days.from_now.change(hour: 11, min: 0).iso8601 }
#     let(:end_time) { 2.days.from_now.change(hour: 12, min: 0).iso8601 }
#     let(:request_params) do
#       {
#         booking: {
#           court_id: court.id,
#           user_id: customer_user.id,
#           start_time: start_time,
#           end_time: end_time,
#           notes: 'Evening practice session'
#         }
#       }
#     end

#     before do
#       post '/api/v0/bookings', params: request_params.to_json, headers: request_headers
#     end

#     it 'creates a booking successfully' do
#       expect(response).to have_http_status(:created)
#       data = response.parsed_body['data']
#       expect(data['court']['id']).to eq(court.id)
#       expect(data['user']['id']).to eq(customer_user.id)
#       expect(data['status']).to eq('confirmed')
#     end

#     it 'returns booking details with calculations' do
#       data = response.parsed_body['data']
#       expect(data['total_amount']).to eq('1200.0')
#       expect(data['duration_minutes']).to eq(60)
#     end
#   end

#   describe 'POST /api/v0/bookings/availability' do
#     let(:request_headers) { headers.merge(auth_headers(auth_token_for(customer_user))) }
#     let(:start_time) { 3.days.from_now.change(hour: 14, min: 0).iso8601 }
#     let(:end_time) { 3.days.from_now.change(hour: 15, min: 0).iso8601 }

#     it 'returns available when the slot is free' do
#       post '/api/v0/bookings/availability', params: {
#         availability: {
#           court_id: court.id,
#           start_time: start_time,
#           end_time: end_time
#         }
#       }.to_json, headers: request_headers

#       expect(response).to have_http_status(:ok)
#       expect(response.parsed_body['data']).to include('available' => true)
#     end

#     it 'returns unavailable when the slot overlaps an existing booking' do
#       create(:booking, court: court, venue: venue, user: customer_user,
#              start_time: 3.days.from_now.change(hour: 14, min: 0),
#              end_time: 3.days.from_now.change(hour: 15, min: 0))

#       post '/api/v0/bookings/availability', params: {
#         availability: {
#           court_id: court.id,
#           start_time: start_time,
#           end_time: end_time
#         }
#       }.to_json, headers: request_headers

#       expect(response).to have_http_status(:ok)
#       expect(response.parsed_body['data']).to include('available' => false)
#     end
#   end

#   describe 'GET /api/v0/bookings' do
#     let(:request_headers) { headers.merge(auth_headers(auth_token_for(owner_user))) }
#     let!(:booking) do
#       create(:booking, court: court, venue: venue, user: customer_user,
#              start_time: 4.days.from_now.change(hour: 10, min: 0),
#              end_time: 4.days.from_now.change(hour: 11, min: 0))
#     end

#     before do
#       get '/api/v0/bookings', headers: request_headers
#     end

#     it 'returns bookings for the venue' do
#       expect(response).to have_http_status(:ok)
#       data = response.parsed_body['data']
#       expect(data).to be_an(Array)
#       expect(data.size).to eq(1)
#       expect(data.first['id']).to eq(booking.id)
#     end
#   end

#   describe 'PATCH /api/v0/bookings/:id/cancel' do
#     let(:request_headers) { headers.merge(auth_headers(auth_token_for(customer_user))) }
#     let!(:booking) do
#       create(:booking, court: court, venue: venue, user: customer_user,
#              start_time: 5.days.from_now.change(hour: 10, min: 0),
#              end_time: 5.days.from_now.change(hour: 11, min: 0))
#     end

#     before do
#       patch "/api/v0/bookings/#{booking.id}/cancel",
#             params: { cancellation_reason: 'Change of plans' }.to_json,
#             headers: request_headers
#     end

#     it 'cancels the booking successfully' do
#       expect(response).to have_http_status(:ok)
#       data = response.parsed_body['data']
#       expect(data['status']).to eq('cancelled')
#       expect(data['cancellation_reason']).to eq('Change of plans')
#     end
#   end
# end
