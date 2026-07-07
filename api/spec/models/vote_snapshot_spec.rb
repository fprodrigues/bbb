require "rails_helper"

RSpec.describe VoteSnapshot, type: :model do
  describe "associations" do
    it "belongs to election and participant" do
      election = create(:election, :closed)
      participant = create(:participant)
      snapshot = create(:vote_snapshot, election: election, participant: participant)

      expect(snapshot.election).to eq(election)
      expect(snapshot.participant).to eq(participant)
    end
  end

  describe "validations" do
    it "validates presence of hour" do
      snapshot = build(:vote_snapshot, hour: nil)

      expect(snapshot).not_to be_valid
      expect(snapshot.errors[:hour]).to include("can't be blank")
    end
  end
end
