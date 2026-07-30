puts "Seeding SeatForge demo data..."

workshops = [
  { title: "Rails Performance Tuning", topic: "rails", description: "Hands-on workshop for improving Rails performance.", active: true },
  { title: "Vue 3 Patterns", topic: "vue", description: "Modern patterns for Vue 3 applications.", active: true },
  { title: "PostgreSQL Concurrency", topic: "database", description: "Understanding locks and transactions in PostgreSQL.", active: true },
  { title: "API Design for Scale", topic: "api", description: "Designing durable versioned APIs.", active: true }
]

workshops.each do |attributes|
  Workshop.find_or_create_by!(title: attributes[:title]) do |workshop|
    workshop.assign_attributes(attributes)
  end
end

workshop_by_topic = Workshop.all.index_by(&:topic)

sessions_payload = [
  { workshop: workshop_by_topic["rails"], starts_at: 3.days.from_now.beginning_of_day + 9.hours, ends_at: 3.days.from_now.beginning_of_day + 12.hours, capacity: 4, status: "scheduled" },
  { workshop: workshop_by_topic["rails"], starts_at: 6.days.from_now.beginning_of_day + 10.hours, ends_at: 6.days.from_now.beginning_of_day + 13.hours, capacity: 3, status: "scheduled" },
  { workshop: workshop_by_topic["vue"], starts_at: 2.days.from_now.beginning_of_day + 14.hours, ends_at: 2.days.from_now.beginning_of_day + 17.hours, capacity: 6, status: "scheduled" },
  { workshop: workshop_by_topic["vue"], starts_at: 5.days.from_now.beginning_of_day + 15.hours, ends_at: 5.days.from_now.beginning_of_day + 18.hours, capacity: 2, status: "scheduled" },
  { workshop: workshop_by_topic["database"], starts_at: 4.days.from_now.beginning_of_day + 9.hours, ends_at: 4.days.from_now.beginning_of_day + 12.hours, capacity: 5, status: "scheduled" },
  { workshop: workshop_by_topic["database"], starts_at: 7.days.from_now.beginning_of_day + 9.hours, ends_at: 7.days.from_now.beginning_of_day + 12.hours, capacity: 2, status: "scheduled" },
  { workshop: workshop_by_topic["api"], starts_at: 1.day.from_now.beginning_of_day + 13.hours, ends_at: 1.day.from_now.beginning_of_day + 16.hours, capacity: 4, status: "scheduled" },
  { workshop: workshop_by_topic["api"], starts_at: 8.days.from_now.beginning_of_day + 13.hours, ends_at: 8.days.from_now.beginning_of_day + 16.hours, capacity: 4, status: "scheduled" }
]

sessions_payload.each do |payload|
  Session.find_or_create_by!(starts_at: payload[:starts_at], workshop: payload[:workshop]) do |session|
    session.assign_attributes(payload.except(:workshop))
  end
end

attendees = [
  { name: "Ana Torres", email: "ana@example.com" },
  { name: "Diego Ruiz", email: "diego@example.com" },
  { name: "Mina Chen", email: "mina@example.com" },
  { name: "Leo Park", email: "leo@example.com" },
  { name: "Sara Morales", email: "sara@example.com" },
  { name: "Nico Alvarez", email: "nico@example.com" },
  { name: "Priya Shah", email: "priya@example.com" },
  { name: "Omar Malik", email: "omar@example.com" }
]

attendees.each do |attributes|
  Attendee.find_or_create_by!(email: attributes[:email]) do |attendee|
    attendee.assign_attributes(attributes)
  end
end

seed_session = Session.order(:starts_at).first
full_session = Session.where(capacity: 2).order(:starts_at).first
seed_attendees = Attendee.order(:created_at).limit(8)

seed_attendees.each_with_index do |attendee, index|
  status = case index
           when 0 then "confirmed"
           when 1 then "held"
           when 2 then "waitlisted"
           when 3 then "cancelled"
           when 4 then "expired"
           else "confirmed"
           end

  Registration.find_or_create_by!(attendee: attendee, session: seed_session) do |registration|
    registration.status = status
    registration.hold_expires_at = status == "held" ? 10.minutes.ago : nil
    registration.confirmed_at = status == "confirmed" ? Time.current : nil
    registration.cancelled_at = status == "cancelled" ? Time.current : nil
  end
end

full_session.registrations.find_or_create_by!(attendee: seed_attendees[0], session: full_session) do |registration|
  registration.status = "confirmed"
  registration.confirmed_at = Time.current
end

full_session.registrations.find_or_create_by!(attendee: seed_attendees[1], session: full_session) do |registration|
  registration.status = "held"
  registration.hold_expires_at = 10.minutes.from_now
end

full_session.registrations.find_or_create_by!(attendee: seed_attendees[2], session: full_session) do |registration|
  registration.status = "waitlisted"
end

full_session.registrations.find_or_create_by!(attendee: seed_attendees[3], session: full_session) do |registration|
  registration.status = "waitlisted"
end

puts "Seed data ready."
