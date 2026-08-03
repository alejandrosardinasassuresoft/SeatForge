class SessionAvailabilityQuery
  Result = Struct.new(
    :capacity,
    :held_seats,
    :confirmed_seats,
    :waitlist_size,
    :available_seats,
    keyword_init: true
  )

  def self.call(...)
    new(...).call
  end

  def initialize(session:, current_time: Time.current)
    @session = session
    @current_time = current_time
  end

  def call
    counts = session.registrations.group(:status).count
    held_seats = session.registrations.active_capacity_consumers(current_time).where(status: "held").count
    confirmed_seats = counts.fetch("confirmed", 0)

    Result.new(
      capacity: session.capacity,
      held_seats: held_seats,
      confirmed_seats: confirmed_seats,
      waitlist_size: counts.fetch("waitlisted", 0),
      available_seats: [session.capacity - held_seats - confirmed_seats, 0].max
    )
  end

  private

  attr_reader :session, :current_time
end
