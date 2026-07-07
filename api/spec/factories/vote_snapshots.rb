FactoryBot.define do
  factory :vote_snapshot do
    election
    participant
    hour { Time.current.beginning_of_hour }
    votes { 0 }
  end
end
