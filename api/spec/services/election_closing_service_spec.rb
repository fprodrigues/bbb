require "rails_helper"

RSpec.describe ElectionClosingService do
  subject(:service) { described_class.new(redis: REDIS) }

  describe "#close!" do
    context "when election is not running" do
      it "raises an error" do
        election = create(:election, :draft)

        expect { service.close!(election) }
          .to raise_error(RuntimeError, "Votação não está em andamento.")
      end
    end

    context "when election is running" do
      let(:election) { create_election_with_participants.first }
      let(:participants) { election.participants.order(:id).to_a }
      let(:first_candidate) { participants.first }
      let(:second_candidate) { participants.second }
      let(:hour) { Time.current.beginning_of_hour.utc.iso8601 }

      before do
        REDIS.incr(vote_key(election.id, first_candidate.id))
        REDIS.incr(vote_key(election.id, first_candidate.id))
        REDIS.incr(vote_key(election.id, second_candidate.id))
        REDIS.incr(total_key(election.id))
        REDIS.incr(total_key(election.id))
        REDIS.incr(total_key(election.id))
        REDIS.incr(hour_key(election.id, hour))
      end

      it "persists final votes on election participants" do
        service.close!(election)

        expect(first_candidate.election_participants.find_by(election: election).final_votes).to eq(2)
        expect(second_candidate.election_participants.find_by(election: election).final_votes).to eq(1)
      end

      it "creates vote snapshots for each hour key" do
        service.close!(election)

        snapshots = VoteSnapshot.where(election: election, hour: Time.zone.parse(hour))

        expect(snapshots.count).to eq(2)
        expect(snapshots.find_by(participant: first_candidate).votes).to eq(2)
        expect(snapshots.find_by(participant: second_candidate).votes).to eq(1)
      end

      it "updates existing vote snapshots" do
        existing = create(
          :vote_snapshot,
          election: election,
          participant: first_candidate,
          hour: Time.zone.parse(hour),
          votes: 0
        )

        service.close!(election)

        expect(existing.reload.votes).to eq(2)
      end

      it "marks the election as closed and sets ended_at" do
        freeze_time = Time.utc(2026, 7, 7, 18, 0, 0)

        travel_to freeze_time do
          closed_election = service.close!(election)

          expect(closed_election.status).to eq("closed")
          expect(closed_election.ended_at).to eq(freeze_time)
        end
      end

      it "clears Redis keys for the election" do
        service.close!(election)

        expect(REDIS.keys("election:#{election.id}:*")).to be_empty
      end

      it "keeps database changes consistent inside a transaction" do
        allow(election).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(election))

        expect { service.close!(election) }.to raise_error(ActiveRecord::RecordInvalid)
        expect(election.reload.status).to eq("running")
        expect(VoteSnapshot.where(election: election)).to be_empty
      end
    end
  end
end
