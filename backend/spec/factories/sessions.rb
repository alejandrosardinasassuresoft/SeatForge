FactoryBot.define do
  factory :session do
    workshop
    capacity { 10 }
    starts_at { 1.day.from_now }
    ends_at { 1.day.from_now + 2.hours }
    status { "scheduled" }
  end
end
