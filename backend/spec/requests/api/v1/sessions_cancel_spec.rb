require 'rails_helper'

RSpec.describe 'Api::V1::Sessions Cancel Endpoint', type: :request do
  include ActiveJob::TestHelper

  let(:session) { create(:session, capacity: 5) }
  let(:attendee_held) { create(:attendee, email: 'held_req@example.com') }
  let(:attendee_confirmed) { create(:attendee, email: 'confirmed_req@example.com') }
  let(:attendee_waitlisted) { create(:attendee, email: 'waitlisted_req@example.com') }

  let!(:held_reg) { create(:registration, session: session, attendee: attendee_held, status: 'held', hold_expires_at: 10.minutes.from_now) }
  let!(:confirmed_reg) { create(:registration, session: session, attendee: attendee_confirmed, status: 'confirmed', confirmed_at: 1.hour.ago) }
  let!(:waitlisted_reg) { create(:registration, session: session, attendee: attendee_waitlisted, status: 'waitlisted') }

  describe 'POST /api/v1/sessions/:id/cancel' do
    context 'with valid cancellation reason' do
      it 'cancels session and affected registrations, returning 200 OK and summary' do
        post "/api/v1/sessions/#{session.id}/cancel", params: { cancellation_reason: 'Unforeseen circumstances' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['id']).to eq(session.id)
        expect(json['status']).to eq('cancelled')
        expect(json['cancellation_reason']).to eq('Unforeseen circumstances')
        expect(json['cancelled_at']).to be_present
        expect(json['cancelled_counts']).to eq({
          'held' => 1,
          'confirmed' => 1,
          'waitlisted' => 1
        })
      end
    end

    context 'with missing or empty cancellation reason' do
      it 'returns 422 Unprocessable Entity with validation_error envelope' do
        post "/api/v1/sessions/#{session.id}/cancel", params: { cancellation_reason: '' }

        expect(response.status).to eq(422)
        json = JSON.parse(response.body)

        expect(json['error']['code']).to eq('validation_error')
        expect(json['error']['details']).to include('Cancellation reason is required')
      end
    end

    context 'when repeating cancellation request' do
      it 'is idempotent and returns 200 OK without side effects' do
        post "/api/v1/sessions/#{session.id}/cancel", params: { cancellation_reason: 'First reason' }
        expect(response).to have_http_status(:ok)

        post "/api/v1/sessions/#{session.id}/cancel", params: { cancellation_reason: 'First reason' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['status']).to eq('cancelled')
        expect(json['cancelled_counts']).to eq({
          'held' => 0,
          'confirmed' => 0,
          'waitlisted' => 0
        })
      end
    end

    context 'when trying to register for a cancelled session' do
      it 'returns 409 Conflict' do
        post "/api/v1/sessions/#{session.id}/cancel", params: { cancellation_reason: 'Session closed' }
        expect(response).to have_http_status(:ok)

        new_attendee = create(:attendee, email: 'new_buyer@example.com')
        post "/api/v1/sessions/#{session.id}/registrations", params: { attendee: { name: new_attendee.name, email: new_attendee.email } }

        expect(response).to have_http_status(:conflict)
        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq('registration_unavailable')
      end
    end
  end
end
