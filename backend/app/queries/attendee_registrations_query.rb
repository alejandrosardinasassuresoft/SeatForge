class AttendeeRegistrationsQuery
  Result = Struct.new(:attendee, :registrations, keyword_init: true)

  def initialize(attendee_id)
    @attendee_id = attendee_id
  end

  def call
    attendee = Attendee.find(@attendee_id)
    registrations = attendee.registrations
      .includes(session: :workshop)
      .order(created_at: :desc)

    Result.new(
      attendee: attendee,
      registrations: registrations.map { |reg| build_registration_json(reg) }
    )
  end

  private

  def build_registration_json(reg)
    {
      id: reg.id,
      status: reg.status,
      session_id: reg.session_id,
      session: {
        id: reg.session.id,
        starts_at: reg.session.starts_at,
        ends_at: reg.session.ends_at,
        workshop_title: reg.session.workshop.title
      },
      hold_expires_at: reg.hold_expires_at,
      confirmed_at: reg.confirmed_at,
      cancelled_at: reg.cancelled_at,
      created_at: reg.created_at
    }
  end
end
