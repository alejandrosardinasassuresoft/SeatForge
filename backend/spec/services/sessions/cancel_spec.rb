require 'rails_helper'

RSpec.describe Sessions::Cancel do
  include ActiveJob::TestHelper

  let(:session) { create(:session, capacity: 5) }
  let(:attendee_held) { create(:attendee, email: 'held@example.com') }
  let(:attendee_confirmed) { create(:attendee, email: 'confirmed@example.com') }
  let(:attendee_waitlisted) { create(:attendee, email: 'waitlisted@example.com') }
  let(:attendee_expired) { create(:attendee, email: 'expired@example.com') }
  let(:attendee_already_cancelled) { create(:attendee, email: 'already_cancelled@example.com') }

  let!(:held_reg) { create(:registration, session: session, attendee: attendee_held, status: 'held', hold_expires_at: 10.minutes.from_now) }
  let!(:confirmed_reg) { create(:registration, session: session, attendee: attendee_confirmed, status: 'confirmed', confirmed_at: 1.hour.ago) }
  let!(:waitlisted_reg) { create(:registration, session: session, attendee: attendee_waitlisted, status: 'waitlisted') }
  let!(:expired_reg) { create(:registration, session: session, attendee: attendee_expired, status: 'expired') }
  let!(:already_cancelled_reg) { create(:registration, session: session, attendee: attendee_already_cancelled, status: 'cancelled', cancelled_at: 2.hours.ago) }

  describe '.call' do
    it 'raises Api::Errors::ValidationError if cancellation_reason is missing or blank' do
      expect {
        described_class.call(session_id: session.id, cancellation_reason: '  ')
      }.to raise_error(Api::Errors::ValidationError) do |error|
        expect(error.code).to eq('validation_error')
        expect(error.details).to include('Cancellation reason is required')
      end
    end

    it 'transactionally cancels session and affected registrations, enqueuing notifications only for held and confirmed attendees' do
      clear_enqueued_jobs

      result = described_class.call(
        session_id: session.id,
        cancellation_reason: 'Instructor emergency'
      )

      expect(result.session.status).to eq('cancelled')
      expect(result.session.cancellation_reason).to eq('Instructor emergency')
      expect(result.session.cancelled_at).to be_present

      expect(result.cancelled_counts).to eq({ held: 1, confirmed: 1, waitlisted: 1 })

      expect(held_reg.reload.status).to eq('cancelled')
      expect(held_reg.cancelled_at).to be_present

      expect(confirmed_reg.reload.status).to eq('cancelled')
      expect(confirmed_reg.cancelled_at).to be_present

      expect(waitlisted_reg.reload.status).to eq('cancelled')
      expect(waitlisted_reg.cancelled_at).to be_present

      expect(expired_reg.reload.status).to eq('expired')
      expect(already_cancelled_reg.reload.status).to eq('cancelled')

      expect(enqueued_jobs.size).to eq(2)
      enqueued_args = enqueued_jobs.map { |j| j[:args] }
      expect(enqueued_args).to contain_exactly(
        ['session_cancelled', held_reg.id],
        ['session_cancelled', confirmed_reg.id]
      )
    end

    it 'is idempotent when called repeatedly and enqueues no duplicate notifications' do
      described_class.call(session_id: session.id, cancellation_reason: 'First call')
      clear_enqueued_jobs

      repeat_result = described_class.call(session_id: session.id, cancellation_reason: 'First call')

      expect(repeat_result.session.status).to eq('cancelled')
      expect(repeat_result.cancelled_counts).to eq({ held: 0, confirmed: 0, waitlisted: 0 })
      expect(enqueued_jobs).to be_empty
    end
  end
end
