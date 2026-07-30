FactoryBot.define do
  factory :registration do
    attendee
    session
    status { "held" }
    hold_expires_at { 10.minutes.from_now }
  end
end
