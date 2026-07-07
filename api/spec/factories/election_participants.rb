FactoryBot.define do
  factory :election_participant do
    election
    participant
    final_votes { 0 }
  end
end
