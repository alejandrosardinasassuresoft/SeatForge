require "rails_helper"

RSpec.describe Sessions::Cancel do
  include ActiveSupport::Testing::TimeHelpers
  include ActiveJob::TestHelper

  subject(:cancel_session) do
    described_class.call(
      session_id: session.id,
      cancellation_reason: "Instructor unavailable",
      current_time: current_time
    )
  end

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:session) { create(:session, capacity: 5, starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours) }

  around do |example|
    travel_to(current_time) { example.run }
  end

  before do
    clear_enqueued_jobs
  end

  it "raises a validation error when the cancellation reason is blank" do
    expect {
      described_class.call(session_id: session.id, cancellation_reason: "  ", current_time: current_time)
    }.to raise_error(Api::Errors::ValidationError) { |error|
      expect(error.code).to eq("validation_error")
      expect(error.details).to include("Cancellation reason is required")
    }
  end

  it "stores cancellation metadata, cancels eligible registrations, and notifies held and confirmed attendees" do
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

    enqueued_args = enqueued_jobs.map { |job| job[:args] }
    expect(enqueued_args).to contain_exactly(
      ["session_cancelled", held.id],
      ["session_cancelled", confirmed.id]
    )
  end

  it "locks the target session while cancelling" do
    expect_any_instance_of(Session).to receive(:with_lock).and_call_original

    cancel_session
  end

  it "is idempotent for an already cancelled session and enqueues no duplicate notifications" do
    held = create(:registration, session: session, status: "held", hold_expires_at: current_time + 5.minutes)
    first_result = cancel_session
    first_cancelled_at = held.reload.cancelled_at
    clear_enqueued_jobs

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
    expect(enqueued_jobs).to be_empty
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