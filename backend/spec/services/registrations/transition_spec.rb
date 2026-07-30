require "rails_helper"

RSpec.describe Registrations::Transition do
  subject(:transition) do
    described_class.call(
      registration_id: registration.id,
      action: action,
      current_time: current_time
    )
  end

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:session) do
    create(
      :session,
      capacity: 1,
      starts_at: current_time + 1.day,
      ends_at: current_time + 1.day + 2.hours
    )
  end
  let(:registration) { create(:registration, session: session, status: "held", hold_expires_at: current_time + 10.minutes) }
  let(:action) { :confirm }

  describe ".call" do
    context "when confirming" do
      it "confirms a held registration" do
        expect(transition.registration.reload.status).to eq("confirmed")
        expect(transition.registration.reload.confirmed_at).to eq(current_time)
        expect(transition.registration.reload.hold_expires_at).to be_nil
      end

      it "is idempotent for an already confirmed registration" do
        registration.update!(status: "confirmed", confirmed_at: current_time - 1.minute, hold_expires_at: nil)

        expect { transition }.not_to change { registration.reload.status }
      end

      it "raises a hold_expired conflict when the hold has already expired" do
        registration.update!(hold_expires_at: current_time - 1.minute)

        expect { transition }.to raise_error(Api::Errors::ConflictError) { |error| expect(error.code).to eq("hold_expired") }
      end
    end

    context "when cancelling" do
      let(:action) { :cancel }

      it "cancels the registration and promotes the oldest waitlisted registration when capacity opens" do
        waitlisted_registration = create(
          :registration,
          session: session,
          status: "waitlisted",
          created_at: 2.hours.ago,
          hold_expires_at: nil
        )

        transition

        expect(registration.reload.status).to eq("cancelled")
        expect(registration.reload.cancelled_at).to eq(current_time)
        expect(waitlisted_registration.reload.status).to eq("held")
        expect(waitlisted_registration.reload.hold_expires_at).to eq(current_time + 10.minutes)
      end

      it "is idempotent for an already cancelled registration" do
        registration.update!(status: "cancelled", cancelled_at: current_time - 1.minute, hold_expires_at: nil)

        expect { transition }.not_to change { registration.reload.status }
      end
    end

    context "when promoting" do
      let(:action) { :promote }

      it "promotes a waitlisted registration when capacity is available" do
        registration.update!(status: "waitlisted", hold_expires_at: nil)

        expect(transition.registration.reload.status).to eq("held")
        expect(transition.registration.reload.hold_expires_at).to eq(current_time + 10.minutes)
      end
    end
  end
end
