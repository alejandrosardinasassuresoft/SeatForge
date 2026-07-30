require "rails_helper"

RSpec.describe Attendee, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:registrations).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:attendee)).to be_valid
    end

    it "requires a name" do
      attendee = build(:attendee, name: nil)

      expect(attendee).not_to be_valid
      expect(attendee.errors[:name]).to include("can't be blank")
    end

    it "requires an email" do
      attendee = build(:attendee, email: nil)

      expect(attendee).not_to be_valid
      expect(attendee.errors[:email]).to include("can't be blank")
    end

    it "normalizes email before validation" do
      attendee = build(:attendee, email: "  Alex@Example.COM  ")

      attendee.valid?

      expect(attendee.email).to eq("alex@example.com")
    end

    it "rejects mixed-case duplicate emails" do
      create(:attendee, email: "alex@example.com")
      duplicate = build(:attendee, email: "Alex@Example.com")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("has already been taken")
    end

    it "protects case-insensitive email uniqueness at the database level" do
      timestamp = Time.current
      Attendee.insert_all!([
        { name: "Alex One", email: "alex@example.com", created_at: timestamp, updated_at: timestamp }
      ])

      expect do
        Attendee.insert_all!([
          { name: "Alex Two", email: "Alex@Example.com", created_at: timestamp, updated_at: timestamp }
        ])
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
