FactoryBot.define do
  factory :workshop do
    sequence(:title) { |n| "Workshop #{n}" }
    description { "Comprehensive workshop description." }
    topic { "Ruby on Rails" }
    active { true }
  end
end
