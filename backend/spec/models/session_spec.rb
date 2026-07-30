require "rails_helper"

RSpec.describe Session, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:workshop) }
    it { is_expected.to have_many(:registrations).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:session)).to be_valid
    end

    it "requires a positive capacity" do
      session = build(:session, capacity: 0)

      expect(session).not_to be_valid
      expect(session.errors[:capacity]).to include("must be greater than 0")
    end

    it "requires starts_at to be before ends_at" do
      starts_at = 1.day.from_now
      session = build(:session, starts_at: starts_at, ends_at: starts_at)

      expect(session).not_to be_valid
      expect(session.errors[:ends_at]).to include("must be after starts at")
    end

    it "rejects unsupported statuses" do
      session = build(:session, status: "archived")

      expect(session).not_to be_valid
      expect(session.errors[:status]).to include("is not included in the list")
    end
  end
end
