require 'rails_helper'

RSpec.describe Registrations::ExpireHoldsJob, type: :job do
  include ActiveJob::TestHelper

  let(:session) { create(:session, capacity: 1) }
  let(:attendee_held) { create(:attendee, email: 'held@example.com') }
  let(:attendee_waitlisted1) { create(:attendee, email: 'waitlist1@example.com') }
  let(:attendee_waitlisted2) { create(:attendee, email: 'waitlist2@example.com') }

  let!(:held_registration) do
    create(:registration, session: session, attendee: attendee_held, status: 'held', hold_expires_at: 5.minutes.ago)
  end

  let!(:waitlisted1) do
    create(:registration, session: session, attendee: attendee_waitlisted1, status: 'waitlisted', created_at: 10.minutes.ago)
  end

  let!(:waitlisted2) do
    create(:registration, session: session, attendee: attendee_waitlisted2, status: 'waitlisted', created_at: 5.minutes.ago)
  end

  describe '#perform' do
    it 'expires holds past hold_expires_at and promotes the oldest waitlisted attendee' do
      expect {
        described_class.new.perform
      }.to have_enqueued_job(Registrations::SendNotificationJob).with('promoted', waitlisted1.id)

      expect(held_registration.reload.status).to eq('expired')
      expect(waitlisted1.reload.status).to eq('held')
      expect(waitlisted1.hold_expires_at).to be > Time.current
      expect(waitlisted2.reload.status).to eq('waitlisted')
    end

    it 'is idempotent when run multiple times' do
      described_class.new.perform

      expect(held_registration.reload.status).to eq('expired')
      expect(waitlisted1.reload.status).to eq('held')
      expect(waitlisted2.reload.status).to eq('waitlisted')

      # Run a second time
      expect {
        described_class.new.perform
      }.not_to change { waitlisted2.reload.status }

      expect(held_registration.reload.status).to eq('expired')
      expect(waitlisted1.reload.status).to eq('held')
      expect(waitlisted2.reload.status).to eq('waitlisted')
    end

    it 'does not expire holds that have not reached hold_expires_at' do
      active_hold = create(:registration, status: 'held', hold_expires_at: 10.minutes.from_now)

      described_class.new.perform

      expect(active_hold.reload.status).to eq('held')
    end

    it 'handles time travel testing cleanly' do
      future_hold = create(:registration, status: 'held', hold_expires_at: 10.minutes.from_now)

      # Fast forward time past expiration
      described_class.new.perform(15.minutes.from_now)

      expect(future_hold.reload.status).to eq('expired')
    end
  end
end
