# frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe 'API V0 Pricing Rules', type: :request do
#   let(:headers) { { 'Content-Type' => 'application/json' } }

#   let(:owner_user) { create(:user, :owner, email: 'owner@example.com') }
#   let(:admin_user) { create(:user, :admin, email: 'admin@example.com') }
#   let(:receptionist_user) { create(:user, :receptionist, email: 'receptionist@example.com') }
#   let(:customer_user) { create(:user, :customer, email: 'customer@example.com') }

#   let(:venue) { create(:venue, owner: owner_user) }
#   let(:court_type) { create(:court_type, name: 'Badminton') }

#   before do
#     create(:venue_user, venue: venue, user: receptionist_user, added_by: owner_user)
#     create(:venue_user, venue: venue, user: admin_user, added_by: owner_user)
#   end

#   let!(:pricing_rule) do
#     create(:pricing_rule,
#            venue: venue,
#            court_type: court_type,
#            name: 'Weekday Evening Peak',
#            day_of_week: nil,
#            start_time: '18:00',
#            end_time: '23:00',
#            priority: 2,
#            is_active: true)
#   end

#   let!(:inactive_pricing_rule) do
#     create(:pricing_rule,
#            venue: venue,
#            court_type: court_type,
#            name: 'Off-Peak Rule',
#            is_active: false,
#            priority: 1)
#   end

#   describe 'GET /api/v0/pricing_rules' do
#     let(:request_headers) { headers.merge(auth_headers(auth_token_for(owner_user))) }

#     before do
#       get '/api/v0/pricing_rules', headers: request_headers
#     end

#     it 'returns success status' do
#       expect(response).to have_http_status(:ok)
#     end

#     it 'returns pricing rules for the venue' do
#       data = response.parsed_body['data']
#       expect(data).to be_an(Array)
#       expect(data.size).to eq(2)
#     end

#     it 'includes court type details' do
#       data = response.parsed_body['data'].first
#       expect(data['court_type']).to include('id' => court_type.id, 'name' => 'Badminton')
#     end

#     it 'filters by active status' do
#       get '/api/v0/pricing_rules', params: { is_active: 'true' }, headers: request_headers
#       data = response.parsed_body['data']
#       expect(data.size).to eq(1)
#       expect(data.first['is_active']).to eq(true)
#     end
#   end

#   describe 'GET /api/v0/pricing_rules/:id' do
#     let(:request_headers) { headers.merge(auth_headers(auth_token_for(receptionist_user))) }

#     before do
#       get "/api/v0/pricing_rules/#{pricing_rule.id}", headers: request_headers
#     end

#     it 'returns success status' do
#       expect(response).to have_http_status(:ok)
#     end

#     it 'returns the pricing rule details' do
#       data = response.parsed_body['data']
#       expect(data).to include(
#         'id' => pricing_rule.id,
#         'name' => 'Weekday Evening Peak',
#         'price_per_hour' => '2500.0',
#         'is_active' => true
#       )
#       expect(data['court_type']).to include('id' => court_type.id)
#     end
#   end

#   describe 'POST /api/v0/pricing_rules' do
#     let(:request_headers) { headers.merge(auth_headers(auth_token_for(owner_user))) }
#     let(:request_params) do
#       {
#         pricing_rule: {
#           court_type_id: court_type.id,
#           name: 'Morning Special',
#           price_per_hour: 1800,
#           day_of_week: 1,
#           start_time: '06:00',
#           end_time: '10:00',
#           priority: 3,
#           is_active: true
#         }
#       }
#     end

#     before do
#       post '/api/v0/pricing_rules', params: request_params.to_json, headers: request_headers
#     end

#     it 'creates a pricing rule successfully' do
#       expect(response).to have_http_status(:created)
#       expect(PricingRule.find_by(name: 'Morning Special')).to be_present
#     end

#     it 'returns pricing rule details' do
#       data = response.parsed_body['data']
#       expect(data).to include('name' => 'Morning Special', 'day_of_week' => 1)
#       expect(data['court_type']).to include('id' => court_type.id)
#     end
#   end

#   describe 'PATCH /api/v0/pricing_rules/:id' do
#     let(:request_headers) { headers.merge(auth_headers(auth_token_for(owner_user))) }
#     let(:request_params) do
#       {
#         pricing_rule: {
#           name: 'Updated Evening Peak',
#           price_per_hour: 2600,
#           priority: 4
#         }
#       }
#     end

#     before do
#       patch "/api/v0/pricing_rules/#{pricing_rule.id}", params: request_params.to_json, headers: request_headers
#     end

#     it 'updates the pricing rule successfully' do
#       expect(response).to have_http_status(:ok)
#       expect(pricing_rule.reload.name).to eq('Updated Evening Peak')
#       expect(pricing_rule.reload.price_per_hour).to eq(BigDecimal('2600'))
#       expect(pricing_rule.reload.priority).to eq(4)
#     end
#   end

#   describe 'DELETE /api/v0/pricing_rules/:id' do
#     let(:request_headers) { headers.merge(auth_headers(auth_token_for(owner_user))) }

#     before do
#       delete "/api/v0/pricing_rules/#{inactive_pricing_rule.id}", headers: request_headers
#     end

#     it 'deletes the pricing rule successfully' do
#       expect(response).to have_http_status(:ok)
#       expect(PricingRule.exists?(inactive_pricing_rule.id)).to be false
#     end
#   end

#   describe 'authorization restrictions' do
#     let(:request_headers) { headers.merge(auth_headers(auth_token_for(customer_user))) }
#     let(:request_params) do
#       {
#         pricing_rule: {
#           court_type_id: court_type.id,
#           name: 'Unauthorized Rule',
#           price_per_hour: 1900,
#           priority: 1,
#           is_active: true
#         }
#       }
#     end

#     it 'prevents customers from creating pricing rules' do
#       post '/api/v0/pricing_rules', params: request_params.to_json, headers: request_headers
#       expect(response).to have_http_status(:forbidden)
#     end
#   end
# end
