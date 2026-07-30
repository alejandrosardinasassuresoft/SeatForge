require 'rails_helper'

RSpec.describe 'Api::V1::Workshops', type: :request do
  describe 'POST /api/v1/workshops' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          workshop: {
            title: 'Advanced Rails 7 API',
            description: 'Learn modern Rails API architecture',
            topic: 'Backend',
            active: true
          }
        }
      end

      it 'creates a new Workshop and returns 201 Created' do
        expect {
          post '/api/v1/workshops', params: valid_attributes
        }.to change(Workshop, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['title']).to eq('Advanced Rails 7 API')
        expect(json['topic']).to eq('Backend')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          workshop: {
            title: '',
            topic: ''
          }
        }
      end

      it 'returns 422 Unprocessable Entity with error contract' do
        post '/api/v1/workshops', params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq('validation_error')
        expect(json['error']['message']).to be_present
      end
    end
  end

  describe 'GET /api/v1/workshops' do
    before do
      create(:workshop, title: 'Alpha Workshop', topic: 'DevOps', active: true, created_at: 2.days.ago)
      create(:workshop, title: 'Beta Workshop', topic: 'Backend', active: true, created_at: 1.day.ago)
      create(:workshop, title: 'Gamma Workshop', topic: 'Backend', active: true, created_at: Time.current)
      create(:workshop, title: 'Inactive Workshop', topic: 'Backend', active: false)
    end

    it 'returns active workshops with HTTP 200 OK' do
      get '/api/v1/workshops'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['workshops'].length).to eq(3)
      titles = json['workshops'].map { |w| w['title'] }
      expect(titles).not_to include('Inactive Workshop')
    end

    it 'filters workshops by topic' do
      get '/api/v1/workshops', params: { topic: 'DevOps' }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['workshops'].length).to eq(1)
      expect(json['workshops'].first['topic']).to eq('DevOps')
    end

    it 'sorts workshops by sort and order parameters' do
      get '/api/v1/workshops', params: { sort: 'title', order: 'asc' }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      titles = json['workshops'].map { |w| w['title'] }
      expect(titles).to eq(['Alpha Workshop', 'Beta Workshop', 'Gamma Workshop'])
    end

    it 'paginates workshops returning pagination metadata' do
      get '/api/v1/workshops', params: { page: 1, per_page: 2 }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['workshops'].length).to eq(2)
      expect(json['pagination']).to include(
        'current_page' => 1,
        'per_page' => 2,
        'total_records' => 3,
        'total_pages' => 2
      )
    end
  end

  describe 'GET /api/v1/workshops/:id' do
    context 'when the workshop exists' do
      let!(:workshop) { create(:workshop, title: 'Target Workshop') }

      it 'returns the workshop details with HTTP 200 OK' do
        get "/api/v1/workshops/#{workshop.id}"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(workshop.id)
        expect(json['title']).to eq('Target Workshop')
      end
    end

    context 'when the workshop does not exist' do
      it 'returns 404 Not Found with error contract' do
        get '/api/v1/workshops/999999'

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq('not_found')
      end
    end
  end

  describe 'POST /api/v1/workshops/:workshop_id/sessions' do
    let!(:workshop) { create(:workshop) }

    context 'with valid session attributes' do
      let(:valid_session_params) do
        {
          session: {
            starts_at: 1.day.from_now.iso8601,
            ends_at: (1.day.from_now + 2.hours).iso8601,
            capacity: 20,
            status: 'scheduled'
          }
        }
      end

      it 'creates a session for the workshop and returns 201 Created' do
        post "/api/v1/workshops/#{workshop.id}/sessions", params: valid_session_params

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['capacity']).to eq(20)
      end
    end

    context 'when workshop does not exist' do
      it 'returns 404 Not Found' do
        post '/api/v1/workshops/999999/sessions', params: { session: { capacity: 10 } }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
