require "rails_helper"

RSpec.describe ElectionParticipant, type: :model do
  describe "associations" do
    it "belongs to election and participant" do
      election = create(:election, :draft)
      participant = create(:participant)
      election_participant = create(:election_participant, election: election, participant: participant)

      expect(election_participant.election).to eq(election)
      expect(election_participant.participant).to eq(participant)
    end
  end

  describe "validations" do
    it "enforces uniqueness of participant within the same election" do
      election = create(:election, :draft)
      participant = create(:participant)
      create(:election_participant, election: election, participant: participant)

      duplicate = build(:election_participant, election: election, participant: participant)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:participant_id]).to include("has already been taken")
    end

    it "allows the same participant in different elections" do
      participant = create(:participant)
      first_election = create(:election, :closed)
      second_election = create(:election, :draft)

      first = create(:election_participant, election: first_election, participant: participant)
      second = build(:election_participant, election: second_election, participant: participant)

      expect(first).to be_persisted
      expect(second).to be_valid
    end
  end
end
