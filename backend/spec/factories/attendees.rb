FactoryBot.define do
  factory :attendee do
    sequence(:name) { |n| "Attendee #{n}" }
    sequence(:email) { |n| "attendee#{n}@example.com" }
  end
end
