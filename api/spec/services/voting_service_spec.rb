require "rails_helper"

RSpec.describe VotingService do
  let(:redis) { FakeRedis.new }
  let(:service) { described_class.new(redis: redis) }

  describe "#vote!" do
    context "when there is no running election" do
      it "raises NoRunningElectionError" do
        create(:election, :draft)

        expect { service.vote!(participant_id: 1) }
          .to raise_error(VotingService::NoRunningElectionError, "Nenhuma votação em andamento.")
      end
    end

    context "when participant is not in the running election" do
      it "raises InvalidParticipantError" do
        election, participants = create_election_with_participants(status: :running)
        outsider = create(:participant)

        expect { service.vote!(participant_id: outsider.id) }
          .to raise_error(
            VotingService::InvalidParticipantError,
            "Participante não disponível para esta votação."
          )
      end
    end

    context "when the vote is valid" do
      let!(:election) { create(:election, :running) }
      let!(:first_participant) { create(:participant) }
      let!(:second_participant) { create(:participant) }

      before do
        create(:election_participant, election: election, participant: first_participant)
        create(:election_participant, election: election, participant: second_participant)
      end

      it "increments participant, total and hourly counters in Redis" do
        freeze_time do
          service.vote!(participant_id: first_participant.id)

          expect(redis.get("election:#{election.id}:participant:#{first_participant.id}:votes").to_i).to eq(1)
          expect(redis.get("election:#{election.id}:total_votes").to_i).to eq(1)

          hour = Time.current.beginning_of_hour.utc.iso8601
          expect(redis.get("election:#{election.id}:hour:#{hour}:votes").to_i).to eq(1)
        end
      end

      it "returns result payload with total_votes, candidates and percentage" do
        result = service.vote!(participant_id: first_participant.id)

        expect(result).to include(
          election_id: election.id,
          status: "running",
          total_votes: 1
        )
        expect(result[:candidates]).to contain_exactly(
          hash_including(participant_id: first_participant.id, votes: 1, percentage: 100.0),
          hash_including(participant_id: second_participant.id, votes: 0, percentage: 0.0)
        )
      end

      it "accumulates multiple votes for the same candidate" do
        3.times { service.vote!(participant_id: first_participant.id) }

        result = ResultsService.new(redis: redis).current_results(election)

        expect(result[:total_votes]).to eq(3)
        expect(result[:candidates].find { |c| c[:participant_id] == first_participant.id }[:votes]).to eq(3)
      end

      it "distributes votes between both candidates with correct percentages" do
        3.times { service.vote!(participant_id: first_participant.id) }
        1.times { service.vote!(participant_id: second_participant.id) }

        result = ResultsService.new(redis: redis).current_results(election)
        first = result[:candidates].find { |c| c[:participant_id] == first_participant.id }
        second = result[:candidates].find { |c| c[:participant_id] == second_participant.id }

        expect(result[:total_votes]).to eq(4)
        expect(first[:votes]).to eq(3)
        expect(second[:votes]).to eq(1)
        expect(first[:percentage]).to eq(75.0)
        expect(second[:percentage]).to eq(25.0)
      end
    end
  end
end
