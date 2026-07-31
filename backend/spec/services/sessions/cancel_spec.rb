require "rails_helper"

RSpec.describe Sessions::Cancel do
  include ActiveSupport::Testing::TimeHelpers

  subject(:cancel_session) do
    described_class.call(
      session_id: session.id,
      cancellation_reason: "Instructor unavailable",
      current_time: current_time
    )
  end

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:session) { create(:session, starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours) }

  around do |example|
    travel_to(current_time) { example.run }
  end

  it "stores cancellation metadata and cancels eligible registrations by prior status" do
    held = create(:registration, session: session, status: "held", hold_expires_at: current_time + 5.minutes)
    confirmed = create(:registration, session: session, status: "confirmed", hold_expires_at: nil, confirmed_at: current_time - 1.hour)
    waitlisted = create(:registration, session: session, status: "waitlisted", hold_expires_at: nil)
    expired = create(:registration, session: session, status: "expired", hold_expires_at: current_time - 1.minute)
    already_cancelled = create(:registration, session: session, status: "cancelled", cancelled_at: current_time - 1.day)

    result = cancel_session

    expect(result.session).to have_attributes(
      status: "cancelled",
      cancellation_reason: "Instructor unavailable",
      cancelled_at: current_time
    )
    expect(result.cancelled_counts).to eq("held" => 1, "confirmed" => 1, "waitlisted" => 1)

    expect(held.reload).to have_attributes(status: "cancelled", cancelled_at: current_time, hold_expires_at: nil)
    expect(confirmed.reload).to have_attributes(status: "cancelled", cancelled_at: current_time)
    expect(waitlisted.reload).to have_attributes(status: "cancelled", cancelled_at: current_time)
    expect(expired.reload.status).to eq("expired")
    expect(expired.cancelled_at).to be_nil
    expect(already_cancelled.reload.cancelled_at).to eq(current_time - 1.day)
  end

  it "locks the target session while cancelling" do
    expect_any_instance_of(Session).to receive(:with_lock).and_call_original

    cancel_session
  end

  it "is idempotent for an already cancelled session" do
    held = create(:registration, session: session, status: "held", hold_expires_at: current_time + 5.minutes)
    first_result = cancel_session
    first_cancelled_at = held.reload.cancelled_at

    second_result = described_class.call(
      session_id: session.id,
      cancellation_reason: "Different reason",
      current_time: current_time + 5.minutes
    )

    expect(second_result.session).to have_attributes(
      status: "cancelled",
      cancellation_reason: "Instructor unavailable",
      cancelled_at: first_result.session.cancelled_at
    )
    expect(second_result.cancelled_counts).to eq("held" => 0, "confirmed" => 0, "waitlisted" => 0)
    expect(held.reload).to have_attributes(status: "cancelled", cancelled_at: first_cancelled_at)
  end

  it "rejects completed sessions" do
    session.update!(status: "completed")

    expect { cancel_session }.to raise_error(Api::Errors::ConflictError) { |error|
      expect(error.code).to eq("session_cancellation_unavailable")
    }
  end

  it "rejects sessions that already started" do
    session.update!(starts_at: current_time - 1.minute, ends_at: current_time + 2.hours)

    expect { cancel_session }.to raise_error(Api::Errors::ConflictError) { |error|
      expect(error.code).to eq("session_cancellation_unavailable")
    }
  end
end