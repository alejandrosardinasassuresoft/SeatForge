require 'rails_helper'

RSpec.describe Registrations::SendNotificationJob, type: :job do
  include ActiveJob::TestHelper

  let(:registration) { create(:registration, status: 'confirmed') }

  it 'enqueues job into default queue' do
    expect {
      described_class.perform_later('confirmed', registration.id)
    }.to have_enqueued_job(described_class).with('confirmed', registration.id).on_queue('default')
  end

  it 'invokes NotificationAdapter when performed' do
    expect(NotificationAdapter).to receive(:notify).with(event_type: 'confirmed', registration_id: registration.id)
    described_class.new.perform('confirmed', registration.id)
  end

  it 'handles session_cancelled event type' do
    expect(NotificationAdapter).to receive(:notify).with(event_type: 'session_cancelled', registration_id: registration.id)
    described_class.new.perform('session_cancelled', registration.id)
  end
end
