require "rails_helper"

RSpec.describe AttendeeRegistrationsQuery do
  include ActiveSupport::Testing::TimeHelpers

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:attendee) { create(:attendee, name: "Jane Doe", email: "jane@example.com") }
  let(:workshop) { create(:workshop, title: "Test Workshop") }
  let(:session1) { create(:session, workshop: workshop,
    starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours) }
  let(:session2) { create(:session, workshop: workshop,
    starts_at: current_time + 2.days, ends_at: current_time + 2.days + 2.hours) }

  around do |example|
    travel_to(current_time) { example.run }
  end

  describe "#call" do
    it "returns attendee info and registrations" do
      reg1 = create(:registration, attendee: attendee, session: session1, status: "confirmed",
        hold_expires_at: nil, confirmed_at: current_time)
      reg2 = create(:registration, attendee: attendee, session: session2, status: "held")

      result = described_class.new(attendee.id).call

      expect(result.attendee.name).to eq("Jane Doe")
      expect(result.attendee.email).to eq("jane@example.com")
      expect(result.registrations.size).to eq(2)
    end

    it "orders registrations by created_at descending" do
      reg1 = create(:registration, attendee: attendee, session: session1, status: "confirmed",
        hold_expires_at: nil, confirmed_at: current_time, created_at: current_time - 2.hours)
      reg2 = create(:registration, attendee: attendee, session: session2, status: "held",
        created_at: current_time - 1.hour)

      result = described_class.new(attendee.id).call

      expect(result.registrations.first[:id]).to eq(reg2.id)
      expect(result.registrations.last[:id]).to eq(reg1.id)
    end

    it "includes session and workshop data" do
      create(:registration, attendee: attendee, session: session1, status: "confirmed",
        hold_expires_at: nil, confirmed_at: current_time)

      result = described_class.new(attendee.id).call

      reg_json = result.registrations.first
      expect(reg_json[:session][:workshop_title]).to eq("Test Workshop")
      expect(reg_json[:session][:id]).to eq(session1.id)
    end

    it "returns empty list when attendee has no registrations" do
      result = described_class.new(attendee.id).call

      expect(result.registrations).to be_empty
    end

    it "raises RecordNotFound for missing attendee" do
      expect { described_class.new(999999).call }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
