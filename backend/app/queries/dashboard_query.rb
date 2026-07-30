class DashboardQuery
  def call(current_time: Time.current)
    today_start = current_time.beginning_of_day
    today_end = current_time.end_of_day

    upcoming_sessions = Session.registration_open(current_time)
    upcoming_count = upcoming_sessions.count

    held_count = Registration.where(status: "held").count
    confirmed_count = Registration.where(status: "confirmed").count
    waitlisted_count = Registration.where(status: "waitlisted").count

    expired_today = Registration.where(status: "expired")
      .where(updated_at: today_start..today_end)
      .count

    full_sessions = find_full_sessions(upcoming_sessions)
    top_waitlisted = find_top_waitlisted_sessions

    {
      upcoming_scheduled_sessions: upcoming_count,
      total_held: held_count,
      total_confirmed: confirmed_count,
      total_waitlisted: waitlisted_count,
      expired_holds_today: expired_today,
      full_sessions: full_sessions,
      top_waitlisted_sessions: top_waitlisted
    }
  end

  private

  def find_full_sessions(sessions)
    full_sessions = sessions
      .where(
        "capacity <= (SELECT COUNT(*) FROM registrations WHERE registrations.session_id = sessions.id AND registrations.status IN ('held', 'confirmed'))"
      )
      .includes(:workshop)
      .order(:starts_at)
      .to_a

    return [] if full_sessions.empty?

    counts = Registration.where(session_id: full_sessions.map(&:id))
      .active_capacity_consumers
      .group(:session_id)
      .count

    full_sessions.map do |session|
      {
        id: session.id,
        starts_at: session.starts_at,
        capacity: session.capacity,
        workshop: session.workshop.title,
        confirmed: counts[session.id].to_i
      }
    end
  end

  def find_top_waitlisted_sessions
    Session.joins(:registrations)
      .includes(:workshop)
      .where(registrations: { status: "waitlisted" })
      .where(status: "scheduled")
      .group(:id)
      .select(
        "sessions.*",
        "COUNT(registrations.id) AS waitlist_count"
      )
      .order(Arel.sql("COUNT(registrations.id) DESC"))
      .limit(3)
      .map do |session|
        {
          id: session.id,
          starts_at: session.starts_at,
          capacity: session.capacity,
          workshop: session.workshop.title,
          waitlist_size: session.waitlist_count
        }
      end
  end
end
