# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V0 Courts', type: :request do
  let(:headers) { { 'Content-Type' => 'application/json' } }

  let(:owner_role) { create(:role, :owner) }
  let(:admin_role) { create(:role, :admin) }
  let(:customer_role) { create(:role, :customer) }

  let(:owner_user) { create(:user, email: 'owner@example.com') }
  let(:admin_user) { create(:user, email: 'admin@example.com') }
  let(:customer_user) { create(:user, email: 'customer@example.com') }

  before do
    owner_user.assign_role(owner_role)
    admin_user.assign_role(admin_role)
    customer_user.assign_role(customer_role)
  end

  let!(:court_type) { create(:court_type, name: 'Badminton') }
  let!(:venue) { create(:venue, name: 'Alpha Arena', owner: owner_user) }

  let!(:active_court) do
    create(:court,
           venue: venue,
           court_type: court_type,
           name: 'Court A',
           is_active: true)
  end

  let!(:inactive_court) do
    create(:court,
           venue: venue,
           court_type: court_type,
           name: 'Court B',
           is_active: false)
  end

  describe 'GET /api/v0/courts' do
    before do
      get '/api/v0/courts', headers: headers
    end

    it 'returns success status' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns court list' do
      data = response.parsed_body['data']
      expect(data).to be_an(Array)
      expect(data.size).to eq(2)
    end

    it 'includes court type details' do
      data = response.parsed_body['data'].first
      expect(data['court_type']).to include('id' => court_type.id, 'name' => 'Badminton')
    end

    it 'includes venue minimal details' do
      data = response.parsed_body['data'].first
      expect(data['venue']).to include('id' => venue.id, 'name' => 'Alpha Arena', 'slug' => venue.slug)
    end
  end

  describe 'GET /api/v0/courts/:id' do
    before do
      get "/api/v0/courts/#{active_court.id}", headers: headers
    end

    it 'returns success status' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns the court details' do
      data = response.parsed_body['data']
      expect(data).to include(
        'id' => active_court.id,
        'name' => 'Court A',
        'is_active' => true
      )
      expect(data['court_type']).to include('id' => court_type.id)
      expect(data['venue']).to include('id' => venue.id)
    end
  end

  describe 'POST /api/v0/courts' do
    let(:endpoint) { '/api/v0/courts' }
    let(:request_headers) { headers }

    let(:court_name) { 'Court C' }
    let(:court_description) { 'Premium badminton court' }
    let(:court_is_active) { true }
    let(:court_venue_id) { venue.id }
    let(:court_court_type_id) { court_type.id }
    let(:request_params) do
      {
        venue_id: court_venue_id,
        court_type_id: court_court_type_id,
        name: court_name,
        description: court_description,
        is_active: court_is_active
      }
    end

    before do
      post endpoint, params: request_params.to_json, headers: request_headers
    end

    # SUCCESS PATHS
    context 'when authenticated as owner' do
      let(:request_headers) { headers.merge('Authorization' => auth_token_for(owner_user)) }

      it 'returns created status' do
        expect(response).to have_http_status(:created)
      end

      it 'creates the court in the database' do
        expect(Court.find_by(name: court_name)).to be_present
      end

      it 'matches the create response schema' do
        expect(response).to match_json_schema('courts/create_response')
      end

      it 'returns the created court details' do
        data = response.parsed_body['data']
        expect(data).to include(
          'name' => court_name,
          'description' => court_description,
          'is_active' => court_is_active
        )
      end

      it 'returns embedded court_type' do
        data = response.parsed_body['data']
        expect(data['court_type']).to include('id' => court_type.id, 'name' => court_type.name)
      end

      it 'returns embedded venue' do
        data = response.parsed_body['data']
        expect(data['venue']).to include('id' => venue.id, 'name' => venue.name)
      end
    end

    context 'when authenticated as admin' do
      let(:request_headers) { headers.merge('Authorization' => auth_token_for(admin_user)) }

      it 'returns created status' do
        expect(response).to have_http_status(:created)
      end
    end

    # FAILURE PATHS
    context 'when not authenticated' do
      it 'returns forbidden status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as customer' do
      let(:request_headers) { headers.merge('Authorization' => auth_token_for(customer_user)) }

      it 'returns forbidden status' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when name is blank' do
      let(:request_headers) { headers.merge('Authorization' => auth_token_for(owner_user)) }
      let(:court_name) { '' }

      it 'returns unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'matches the error response schema' do
        expect(response).to match_json_schema('error_response')
      end
    end

    context 'when venue_id is missing' do
      let(:request_headers) { headers.merge('Authorization' => auth_token_for(owner_user)) }
      let(:court_venue_id) { nil }

      it 'returns unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when court_type_id is missing' do
      let(:request_headers) { headers.merge('Authorization' => auth_token_for(owner_user)) }
      let(:court_court_type_id) { nil }

      it 'returns unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when venue does not exist' do
      let(:request_headers) { headers.merge('Authorization' => auth_token_for(owner_user)) }
      let(:court_venue_id) { 999_999 }

      it 'returns not found status' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when court_type does not exist' do
      let(:request_headers) { headers.merge('Authorization' => auth_token_for(owner_user)) }
      let(:court_court_type_id) { 999_999 }

      it 'returns not found status' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /api/v0/courts/:id' do
    let(:request_headers) { headers.merge('Authorization' => auth_token_for(owner_user)) }
    let(:request_params) do
      {
        name: 'Court A Updated',
        is_active: false
      }
    end

    before do
      patch "/api/v0/courts/#{active_court.id}", params: request_params.to_json, headers: request_headers
    end

    it 'updates the court successfully' do
      expect(response).to have_http_status(:ok)
      expect(active_court.reload.name).to eq('Court A Updated')
      expect(active_court.reload.is_active).to eq(false)
    end
  end

  describe 'DELETE /api/v0/courts/:id' do
    let(:request_headers) { headers.merge('Authorization' => auth_token_for(owner_user)) }

    before do
      delete "/api/v0/courts/#{inactive_court.id}", headers: request_headers
    end

    it 'deletes the court successfully' do
      expect(response).to have_http_status(:ok)
      expect(Court.exists?(inactive_court.id)).to be false
    end

    it 'returns a success message' do
      expect(response.parsed_body['data']).to include('message' => 'Court deleted successfully')
    end
  end

  describe 'authorization restrictions' do
    let(:request_headers) { headers.merge('Authorization' => auth_token_for(customer_user)) }

    let(:create_params) do
      {
        venue_id: venue.id,
        court_type_id: court_type.id,
        name: 'Court Unauthorized',
        description: 'Unauthorized court',
        is_active: true
      }
    end

    let(:update_params) do
      {
        name: 'Court Unauthorized',
        is_active: true
      }
    end

    it 'prevents customers from creating courts' do
      post '/api/v0/courts', params: create_params.to_json, headers: request_headers
      expect(response).to have_http_status(:forbidden)
    end

    it 'prevents customers from updating courts' do
      patch "/api/v0/courts/#{active_court.id}", params: update_params.to_json, headers: request_headers
      expect(response).to have_http_status(:forbidden)
    end

    it 'prevents customers from deleting courts' do
      delete "/api/v0/courts/#{active_court.id}", headers: request_headers
      expect(response).to have_http_status(:forbidden)
    end
  end
end
