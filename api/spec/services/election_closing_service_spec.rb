require "rails_helper"

RSpec.describe ElectionClosingService do
  let(:redis) { FakeRedis.new }
  let(:service) { described_class.new(redis: redis) }

  describe "#close!" do
    context "when election is not running" do
      it "raises an error" do
        election = create(:election, :draft)

        expect { service.close!(election) }
          .to raise_error("Votação não está em andamento.")
      end
    end

    context "when election is running" do
      let!(:election) { create(:election, :running) }
      let!(:first_participant) { create(:participant) }
      let!(:second_participant) { create(:participant) }
      let!(:first_election_participant) do
        create(:election_participant, election: election, participant: first_participant)
      end
      let!(:second_election_participant) do
        create(:election_participant, election: election, participant: second_participant)
      end

      before do
        freeze_time do
          hour = Time.current.beginning_of_hour.utc.iso8601

          redis.incr("election:#{election.id}:participant:#{first_participant.id}:votes")
          redis.incr("election:#{election.id}:participant:#{first_participant.id}:votes")
          redis.incr("election:#{election.id}:participant:#{second_participant.id}:votes")
          redis.incr("election:#{election.id}:hour:#{hour}:votes")
          redis.incr("election:#{election.id}:hour:#{hour}:votes")
          redis.incr("election:#{election.id}:hour:#{hour}:votes")
        end
      end

      it "persists final votes, snapshots and closes the election in a transaction" do
        freeze_time do
          closed_election = service.close!(election)

          expect(closed_election.status).to eq("closed")
          expect(closed_election.ended_at).to eq(Time.current)

          expect(first_election_participant.reload.final_votes).to eq(2)
          expect(second_election_participant.reload.final_votes).to eq(1)

          hour = Time.current.beginning_of_hour
          expect(
            VoteSnapshot.find_by(
              election: election,
              participant: first_participant,
              hour: hour
            ).votes
          ).to eq(2)
          expect(
            VoteSnapshot.find_by(
              election: election,
              participant: second_participant,
              hour: hour
            ).votes
          ).to eq(1)
        end
      end

      it "updates existing vote snapshots" do
        hour = Time.current.beginning_of_hour
        snapshot = create(
          :vote_snapshot,
          election: election,
          participant: first_participant,
          hour: hour,
          votes: 0
        )

        service.close!(election)

        expect(snapshot.reload.votes).to eq(2)
      end
    end
  end
end
