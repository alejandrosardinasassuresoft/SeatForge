require "rails_helper"

RSpec.describe Registrations::Allocate do
  subject(:allocate) do
    described_class.call(
      session_id: session.id,
      attendee_params: attendee_params,
      current_time: current_time
    )
  end

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:session) { create(:session, capacity: 2, starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours) }
  let(:attendee_params) { { name: "Alejandro Sardinas", email: " Alejandro@Example.COM " } }

  it "creates a held registration with a UTC ten-minute expiration when capacity remains" do
    result = allocate
    registration = result.registration

    expect(registration).to be_persisted
    expect(registration.status).to eq("held")
    expect(registration.hold_expires_at).to eq(current_time + 10.minutes)
    expect(registration.hold_expires_at.utc?).to be(true)
    expect(result.attendee.email).to eq("alejandro@example.com")
  end

  it "reuses an attendee by normalized email" do
    attendee = create(:attendee, name: "Existing Alejandro", email: "alejandro@example.com")

    expect(allocate.attendee).to eq(attendee)
  end


  it "locks the target session while allocating" do
    expect_any_instance_of(Session).to receive(:with_lock).and_call_original

    allocate
  end
  it "creates a waitlisted registration when capacity is full" do
    create(:registration, session: session, status: "held")
    create(:registration, session: session, status: "confirmed", hold_expires_at: nil, confirmed_at: current_time)

    registration = allocate.registration

    expect(registration.status).to eq("waitlisted")
    expect(registration.hold_expires_at).to be_nil
  end

  it "allocates a held seat when an earlier hold has expired" do
    create(:registration, session: session, status: "held", hold_expires_at: current_time)
    create(:registration, session: session, status: "confirmed", hold_expires_at: nil, confirmed_at: current_time)

    expect(allocate.registration.status).to eq("held")
  end

  it "does not let repeated allocations exceed active capacity" do
    capacity_one_session = create(
      :session,
      capacity: 1,
      starts_at: current_time + 2.days,
      ends_at: current_time + 2.days + 2.hours
    )

    3.times do |index|
      described_class.call(
        session_id: capacity_one_session.id,
        attendee_params: { name: "Attendee #{index}", email: "attendee#{index}@example.com" },
        current_time: current_time
      )
    end

    expect(capacity_one_session.registrations.active_capacity_consumers(current_time).count).to eq(1)
    expect(capacity_one_session.registrations.where(status: "waitlisted").count).to eq(2)
  end

  it "rejects cancelled sessions" do
    session.update!(status: "cancelled")

    expect { allocate }.to raise_error(Api::Errors::ConflictError) { |error|
      expect(error.code).to eq("registration_unavailable")
    }
  end

  it "rejects completed sessions" do
    session.update!(status: "completed")

    expect { allocate }.to raise_error(Api::Errors::ConflictError) { |error|
      expect(error.code).to eq("registration_unavailable")
    }
  end

  it "rejects started sessions" do
    session.update!(starts_at: current_time - 1.minute, ends_at: current_time + 2.hours)

    expect { allocate }.to raise_error(Api::Errors::ConflictError) { |error|
      expect(error.code).to eq("registration_unavailable")
    }
  end

  it "rejects duplicate active registrations for the same session" do
    attendee = create(:attendee, email: "alejandro@example.com")
    create(:registration, attendee: attendee, session: session, status: "waitlisted", hold_expires_at: nil)

    expect { allocate }.to raise_error(Api::Errors::ConflictError) { |error|
      expect(error.code).to eq("duplicate_registration")
    }
  end

  it "rejects overlapping held or confirmed registrations" do
    attendee = create(:attendee, email: "alejandro@example.com")
    overlapping_session = create(
      :session,
      starts_at: session.starts_at + 30.minutes,
      ends_at: session.ends_at + 30.minutes
    )
    create(:registration, attendee: attendee, session: overlapping_session, status: "held")

    expect { allocate }.to raise_error(Api::Errors::ConflictError) { |error|
      expect(error.code).to eq("registration_schedule_conflict")
    }
  end

  it "allows waitlisted registrations in overlapping session windows" do
    attendee = create(:attendee, email: "alejandro@example.com")
    overlapping_session = create(
      :session,
      starts_at: session.starts_at + 30.minutes,
      ends_at: session.ends_at + 30.minutes
    )
    create(:registration, attendee: attendee, session: overlapping_session, status: "waitlisted", hold_expires_at: nil)

    expect(allocate.registration.status).to eq("held")
  end

  it "does not create attendees when the session is missing" do
    attendee_count = Attendee.count

    expect {
      described_class.call(session_id: 999999, attendee_params: attendee_params, current_time: current_time)
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect(Attendee.count).to eq(attendee_count)
  end

  it "raises a validation error for invalid attendee input" do
    invalid_params = { name: "", email: "" }

    expect {
      described_class.call(session_id: session.id, attendee_params: invalid_params, current_time: current_time)
    }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
