require "rails_helper"

RSpec.describe Participant, type: :model do
  describe "validations" do
    it "validates presence of name" do
      participant = build(:participant, name: nil)

      expect(participant).not_to be_valid
      expect(participant.errors[:name]).to include("can't be blank")
    end

    it "validates uniqueness of name" do
      create(:participant, name: "Ana")
      duplicate = build(:participant, name: "Ana")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end
  end

  describe "defaults" do
    it "defaults active to true" do
      participant = create(:participant)

      expect(participant.active).to be(true)
    end
  end

  describe "associations" do
    it "has many election_participants" do
      participant = create(:participant)
      election = create(:election, :running)
      election_participant = create(:election_participant, participant: participant, election: election)

      expect(participant.election_participants).to contain_exactly(election_participant)
    end

    it "has many elections through election_participants" do
      participant = create(:participant)
      election = create(:election, :running)
      create(:election_participant, participant: participant, election: election)

      expect(participant.elections).to contain_exactly(election)
    end
  end
end
