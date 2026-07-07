FactoryBot.define do
  factory :participant do
    sequence(:name) { |n| "Participante #{n}" }
    avatar_url { "https://example.com/avatar.png" }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
