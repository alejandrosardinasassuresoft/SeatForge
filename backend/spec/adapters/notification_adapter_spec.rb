require 'rails_helper'

RSpec.describe NotificationAdapter do
  let(:workshop) { create(:workshop, title: 'GraphQL Masterclass') }
  let(:session) { create(:session, workshop: workshop) }
  let(:attendee) { create(:attendee, name: 'Alice Smith', email: 'alice@example.com') }
  let(:registration) { create(:registration, session: session, attendee: attendee, status: 'confirmed') }

  after do
    NotificationAdapter.reset!
  end

  describe '.notify' do
    it 'logs structured notification using LoggerAdapter by default' do
      expect(Rails.logger).to receive(:info).with(/\[NOTIFICATION\] Event: CONFIRMED \| To: Alice Smith <alice@example\.com>/)

      result = NotificationAdapter.notify(event_type: 'confirmed', registration_id: registration.id)
      expect(result[:event_type]).to eq('confirmed')
      expect(result[:registration_id]).to eq(registration.id)
    end

    it 'allows replacing the adapter dynamically' do
      custom_adapter = double('CustomAdapter')
      expect(custom_adapter).to receive(:notify).with(event_type: 'promoted', registration_id: registration.id).and_return(:ok)

      NotificationAdapter.adapter = custom_adapter
      expect(NotificationAdapter.notify(event_type: 'promoted', registration_id: registration.id)).to eq(:ok)
    end

    it 'gracefully returns nil if registration is not found' do
      expect(Rails.logger).not_to receive(:info)
      result = NotificationAdapter.notify(event_type: 'confirmed', registration_id: 999_999)
      expect(result).to be_nil
    end
  end
end
