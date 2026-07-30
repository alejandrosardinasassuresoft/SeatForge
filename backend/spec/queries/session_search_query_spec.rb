require "rails_helper"

RSpec.describe SessionSearchQuery do
  include ActiveSupport::Testing::TimeHelpers

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:workshop_rails) { create(:workshop, topic: "rails", title: "Rails Workshop") }
  let(:workshop_vue) { create(:workshop, topic: "vue", title: "Vue Workshop") }

  around do |example|
    travel_to(current_time) { example.run }
  end

  before do
    create(:session, workshop: workshop_rails, capacity: 3,
      starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours)
    create(:session, workshop: workshop_rails, capacity: 2,
      starts_at: current_time + 2.days, ends_at: current_time + 2.days + 2.hours)
    create(:session, workshop: workshop_vue, capacity: 5,
      starts_at: current_time + 3.days, ends_at: current_time + 3.days + 2.hours)
    create(:session, workshop: workshop_vue, capacity: 1,
      starts_at: current_time + 4.days, ends_at: current_time + 4.days + 2.hours)
  end

  describe "#call" do
    it "returns all scheduled sessions by default" do
      result = described_class.new({}).call

      expect(result.sessions.size).to eq(4)
      expect(result.pagination[:total_records]).to eq(4)
    end

    it "filters by topic" do
      result = described_class.new(topic: "rails").call

      expect(result.sessions.size).to eq(2)
      expect(result.sessions.map { |s| s.workshop.topic }).to all(eq("rails"))
    end

    it "filters by date range using from" do
      result = described_class.new(from: (current_time + 2.days).iso8601).call

      expect(result.sessions.size).to eq(3)
    end

    it "filters by date range using to" do
      result = described_class.new(to: (current_time + 2.days + 3.hours).iso8601).call

      expect(result.sessions.size).to eq(2)
    end

    it "filters by date range using both from and to" do
      result = described_class.new(
        from: (current_time + 2.days).iso8601,
        to: (current_time + 3.days + 3.hours).iso8601
      ).call

      expect(result.sessions.size).to eq(2)
    end

    it "filters available sessions only" do
      full = Session.find_by(capacity: 1)
      create(:registration, session: full, status: "held")

      result = described_class.new(available: "true").call

      expect(result.sessions).not_to include(full)
    end

    it "sorts by starts_at ascending by default" do
      result = described_class.new({}).call

      expect(result.sessions.map(&:id)).to eq(result.sessions.sort_by(&:starts_at).map(&:id))
    end

    it "sorts by capacity" do
      result = described_class.new(sort: "capacity", order: "desc").call

      capacities = result.sessions.map(&:capacity)
      expect(capacities).to eq(capacities.sort.reverse)
    end

    it "paginates results" do
      result = described_class.new(page: 1, per_page: 2).call

      expect(result.sessions.size).to eq(2)
      expect(result.pagination[:current_page]).to eq(1)
      expect(result.pagination[:per_page]).to eq(2)
      expect(result.pagination[:total_records]).to eq(4)
      expect(result.pagination[:total_pages]).to eq(2)
    end

    it "caps per_page at 50" do
      result = described_class.new(per_page: 100).call

      expect(result.pagination[:per_page]).to eq(50)
    end

    it "handles invalid page gracefully" do
      result = described_class.new(page: 0).call

      expect(result.pagination[:current_page]).to eq(1)
    end

    it "returns empty result when page exceeds total" do
      result = described_class.new(page: 99).call

      expect(result.sessions).to be_empty
    end
  end
end
