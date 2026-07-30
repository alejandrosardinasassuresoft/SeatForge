require "rails_helper"

RSpec.describe Registration, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:attendee) }
    it { is_expected.to belong_to(:session) }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:registration)).to be_valid
    end

    it "rejects unsupported statuses" do
      registration = build(:registration, status: "pending")

      expect(registration).not_to be_valid
      expect(registration.errors[:status]).to include("is not included in the list")
    end

    it "rejects a duplicate active registration for the same attendee and session" do
      existing = create(:registration, status: "held")
      duplicate = build(:registration, attendee: existing.attendee, session: existing.session, status: "confirmed")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:base]).to include("attendee already has an active registration for this session")
    end

    it "allows one active registration after a cancelled registration" do
      existing = create(:registration, status: "cancelled", cancelled_at: Time.current, hold_expires_at: nil)
      active = build(:registration, attendee: existing.attendee, session: existing.session, status: "held")

      expect(active).to be_valid
    end

    it "allows one active registration after an expired registration" do
      existing = create(:registration, status: "expired", hold_expires_at: 1.hour.ago)
      active = build(:registration, attendee: existing.attendee, session: existing.session, status: "waitlisted")

      expect(active).to be_valid
    end

    it "protects duplicate active registrations at the database level" do
      attendee = create(:attendee)
      session = create(:session)
      timestamp = Time.current

      Registration.insert_all!([
        {
          attendee_id: attendee.id,
          session_id: session.id,
          status: "held",
          created_at: timestamp,
          updated_at: timestamp
        }
      ])

      expect do
        Registration.insert_all!([
          {
            attendee_id: attendee.id,
            session_id: session.id,
            status: "waitlisted",
            created_at: timestamp,
            updated_at: timestamp
          }
        ])
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
