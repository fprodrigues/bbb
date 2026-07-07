require "rails_helper"

RSpec.describe Election, type: :model do
  describe "validations" do
    it "accepts draft, running and closed statuses" do
      Election::STATUSES.each do |status|
        election = build(:election, status: status)

        expect(election).to be_valid
      end
    end

    it "rejects invalid status" do
      election = build(:election, status: "invalid")

      expect(election).not_to be_valid
      expect(election.errors[:status]).to include("is not included in the list")
    end
  end

  describe "scopes" do
    let!(:draft_election) { create(:election, :draft, created_at: 3.hours.ago) }
    let!(:running_election) { create(:election, :running, created_at: 2.hours.ago) }
    let!(:closed_election) { create(:election, :closed, ended_at: 1.hour.ago) }

    describe ".current" do
      it "returns draft and running elections ordered by created_at desc" do
        expect(Election.current).to eq([running_election, draft_election])
      end
    end

    describe ".running" do
      it "returns only running elections" do
        expect(Election.running).to eq([running_election])
      end
    end

    describe ".closed" do
      it "returns only closed elections ordered by ended_at desc" do
        expect(Election.closed).to eq([closed_election])
      end
    end
  end

  describe "status predicates" do
    it "responds to draft?, running? and closed?" do
      expect(build(:election, :draft).draft?).to be(true)
      expect(build(:election, :running).running?).to be(true)
      expect(build(:election, :closed).closed?).to be(true)
    end
  end
end
