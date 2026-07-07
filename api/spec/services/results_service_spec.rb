require "rails_helper"

RSpec.describe ResultsService do
  subject(:service) { described_class.new(redis: REDIS) }

  describe "#current_results" do
    context "when there is no election" do
      it "returns empty results" do
        expect(service.current_results).to eq(
          election_id: nil,
          status: "none",
          total_votes: 0,
          candidates: []
        )
      end
    end

    context "when election has no votes" do
      it "returns participants with zero votes and zero percent" do
        election, participants = create_election_with_participants

        result = service.current_results(election)

        expect(result[:election_id]).to eq(election.id)
        expect(result[:status]).to eq("running")
        expect(result[:total_votes]).to eq(0)
        expect(result[:candidates]).to contain_exactly(
          hash_including(participant_id: participants.first.id, votes: 0, percentage: 0.0),
          hash_including(participant_id: participants.second.id, votes: 0, percentage: 0.0)
        )
      end
    end

    context "when election has votes in Redis" do
      it "returns totals, per-candidate votes and percentages" do
        election, participants = create_election_with_participants
        first_candidate = participants.first
        second_candidate = participants.second

        REDIS.incr(vote_key(election.id, first_candidate.id))
        REDIS.incr(vote_key(election.id, first_candidate.id))
        REDIS.incr(vote_key(election.id, second_candidate.id))

        result = service.current_results(election)

        expect(result[:total_votes]).to eq(3)
        expect(result[:candidates].find { |c| c[:participant_id] == first_candidate.id }).to include(
          votes: 2,
          percentage: 66.67
        )
        expect(result[:candidates].find { |c| c[:participant_id] == second_candidate.id }).to include(
          votes: 1,
          percentage: 33.33
        )
      end
    end
  end

  describe "#hourly_results" do
    context "when there is no election" do
      it "returns an empty hours list" do
        expect(service.hourly_results).to eq(election_id: nil, hours: [])
      end
    end

    context "when Redis has hourly keys" do
      it "returns hours sorted chronologically" do
        election, = create_election_with_participants
        earlier = "2026-07-07T12:00:00Z"
        later = "2026-07-07T13:00:00Z"

        REDIS.incr(hour_key(election.id, later))
        REDIS.incr(hour_key(election.id, earlier))
        REDIS.incr(hour_key(election.id, earlier))

        result = service.hourly_results(election)

        expect(result[:election_id]).to eq(election.id)
        expect(result[:hours]).to eq(
          [
            { hour: earlier, total_votes: 2 },
            { hour: later, total_votes: 1 }
          ]
        )
      end
    end
  end
end
