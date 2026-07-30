require "rails_helper"

RSpec.describe DashboardQuery do
  include ActiveSupport::Testing::TimeHelpers

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:workshop) { create(:workshop) }
  let(:session1) { create(:session, workshop: workshop, capacity: 2,
    starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours) }
  let(:session2) { create(:session, workshop: workshop, capacity: 5,
    starts_at: current_time + 2.days, ends_at: current_time + 2.days + 2.hours) }

  around do |example|
    travel_to(current_time) { example.run }
  end

  describe "#call" do
    before do
      create(:registration, session: session1, status: "held")
      create(:registration, session: session1, status: "confirmed", hold_expires_at: nil, confirmed_at: current_time)
      create(:registration, session: session2, status: "held")
      create(:registration, session: session2, status: "waitlisted")
      create(:registration, session: session2, status: "waitlisted")
      create(:registration, session: session2, status: "cancelled", cancelled_at: current_time)
    end

    it "counts upcoming scheduled sessions" do
      metrics = described_class.new.call(current_time: current_time)

      expect(metrics[:upcoming_scheduled_sessions]).to eq(2)
    end

    it "counts total held registrations" do
      metrics = described_class.new.call(current_time: current_time)

      expect(metrics[:total_held]).to eq(2)
    end

    it "counts total confirmed registrations" do
      metrics = described_class.new.call(current_time: current_time)

      expect(metrics[:total_confirmed]).to eq(1)
    end

    it "counts total waitlisted registrations" do
      metrics = described_class.new.call(current_time: current_time)

      expect(metrics[:total_waitlisted]).to eq(2)
    end

    it "counts expired holds today" do
      create(:registration, status: "expired",
        updated_at: current_time.beginning_of_day + 1.hour)

      metrics = described_class.new.call(current_time: current_time)

      expect(metrics[:expired_holds_today]).to eq(1)
    end

    it "detects full sessions" do
      metrics = described_class.new.call(current_time: current_time)

      expect(metrics[:full_sessions].size).to eq(1)
      expect(metrics[:full_sessions].first[:id]).to eq(session1.id)
    end

    it "returns up to three sessions sorted by waitlist size descending" do
      session3 = create(:session, workshop: workshop, capacity: 3,
        starts_at: current_time + 3.days, ends_at: current_time + 3.days + 2.hours)
      create(:registration, session: session3, status: "waitlisted")
      create(:registration, session: session3, status: "waitlisted")
      create(:registration, session: session3, status: "waitlisted")

      metrics = described_class.new.call(current_time: current_time)

      expect(metrics[:top_waitlisted_sessions].size).to eq(2)
      expect(metrics[:top_waitlisted_sessions].first[:waitlist_size]).to eq(3)
      expect(metrics[:top_waitlisted_sessions].last[:waitlist_size]).to eq(2)
    end

    it "handles zero data gracefully" do
      Registration.delete_all
      Session.delete_all

      metrics = described_class.new.call(current_time: current_time)

      expect(metrics[:upcoming_scheduled_sessions]).to eq(0)
      expect(metrics[:total_held]).to eq(0)
      expect(metrics[:full_sessions]).to be_empty
      expect(metrics[:top_waitlisted_sessions]).to be_empty
    end
  end
end
