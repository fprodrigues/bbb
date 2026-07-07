FactoryBot.define do
  factory :election do
    trait :draft do
      status { "draft" }
    end

    trait :running do
      status { "running" }
      started_at { Time.current }
    end

    trait :closed do
      status { "closed" }
      started_at { 2.hours.ago }
      ended_at { 1.hour.ago }
    end
  end
end
