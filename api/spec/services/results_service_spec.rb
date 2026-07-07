require "rails_helper"

RSpec.describe ResultsService do
  let(:redis) { FakeRedis.new }
  let(:service) { described_class.new(redis: redis) }

  describe "#current_results" do
    context "when there is no election" do
      it "returns empty result payload" do
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
        election, participants = create_election_with_participants(status: :running)

        result = service.current_results(election)

        expect(result[:election_id]).to eq(election.id)
        expect(result[:total_votes]).to eq(0)
        expect(result[:candidates]).to contain_exactly(
          hash_including(participant_id: participants[0].id, votes: 0, percentage: 0.0),
          hash_including(participant_id: participants[1].id, votes: 0, percentage: 0.0)
        )
      end
    end

    context "when election has votes in Redis" do
      it "returns totals, votes per candidate and correct percentages" do
        election, participants = create_election_with_participants(status: :running)

        redis.incr("election:#{election.id}:participant:#{participants[0].id}:votes")
        redis.incr("election:#{election.id}:participant:#{participants[0].id}:votes")
        redis.incr("election:#{election.id}:participant:#{participants[1].id}:votes")

        result = service.current_results(election)
        first = result[:candidates].find { |c| c[:participant_id] == participants[0].id }
        second = result[:candidates].find { |c| c[:participant_id] == participants[1].id }

        expect(result[:total_votes]).to eq(3)
        expect(first[:votes]).to eq(2)
        expect(second[:votes]).to eq(1)
        expect(first[:percentage]).to eq(66.67)
        expect(second[:percentage]).to eq(33.33)
      end
    end
  end

  describe "#hourly_results" do
    context "when there is no election" do
      it "returns empty hours list" do
        expect(service.hourly_results).to eq(election_id: nil, hours: [])
      end
    end

    context "when Redis has hourly keys" do
      it "returns hours sorted chronologically" do
        election, = create_election_with_participants(status: :running)

        redis.incr("election:#{election.id}:hour:2026-07-06T20:00:00Z:votes")
        redis.incr("election:#{election.id}:hour:2026-07-06T20:00:00Z:votes")
        redis.incr("election:#{election.id}:hour:2026-07-06T21:00:00Z:votes")

        result = service.hourly_results(election)

        expect(result[:election_id]).to eq(election.id)
        expect(result[:hours]).to eq(
          [
            { hour: "2026-07-06T20:00:00Z", total_votes: 2 },
            { hour: "2026-07-06T21:00:00Z", total_votes: 1 }
          ]
        )
      end
    end
  end
end
