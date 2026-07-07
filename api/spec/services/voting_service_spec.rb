require "rails_helper"

RSpec.describe VotingService do
  subject(:service) { described_class.new(redis: REDIS) }

  describe "#vote!" do
    context "when there is no running election" do
      it "raises NoRunningElectionError" do
        expect { service.vote!(participant_id: 1) }
          .to raise_error(VotingService::NoRunningElectionError, "Nenhuma votação em andamento.")
      end
    end

    context "when participant does not belong to the running election" do
      it "raises InvalidParticipantError" do
        _election, participants = create_election_with_participants
        outsider = create(:participant, name: "Fora da votação")

        expect { service.vote!(participant_id: outsider.id) }
          .to raise_error(VotingService::InvalidParticipantError, "Participante não disponível para esta votação.")
      end
    end

    context "when the vote is valid" do
      let(:election) { create_election_with_participants.first }
      let(:participants) { election.participants.order(:id).to_a }
      let(:candidate) { participants.first }

      it "increments participant, total and hourly counters in Redis" do
        freeze_time = Time.utc(2026, 7, 7, 15, 30, 0)

        travel_to freeze_time do
          service.vote!(participant_id: candidate.id)

          expect(REDIS.get(vote_key(election.id, candidate.id)).to_i).to eq(1)
          expect(REDIS.get(total_key(election.id)).to_i).to eq(1)
          expect(REDIS.get(hour_key(election.id)).to_i).to eq(1)
        end
      end

      it "returns updated results with total_votes, candidates and percentage" do
        result = service.vote!(participant_id: candidate.id)

        expect(result[:election_id]).to eq(election.id)
        expect(result[:status]).to eq("running")
        expect(result[:total_votes]).to eq(1)
        expect(result[:candidates]).to contain_exactly(
          hash_including(participant_id: candidate.id, votes: 1, percentage: 100.0),
          hash_including(participant_id: participants.second.id, votes: 0, percentage: 0.0)
        )
      end
    end

    context "with multiple votes for the same candidate" do
      let(:election) { create_election_with_participants.first }
      let(:candidate) { election.participants.order(:id).first }

      it "accumulates votes for the candidate" do
        3.times { service.vote!(participant_id: candidate.id) }

        result = ResultsService.new(redis: REDIS).current_results(election)

        expect(result[:total_votes]).to eq(3)
        expect(result[:candidates].find { |c| c[:participant_id] == candidate.id }[:votes]).to eq(3)
        expect(result[:candidates].find { |c| c[:participant_id] == candidate.id }[:percentage]).to eq(100.0)
      end
    end

    context "with votes distributed between candidates" do
      let(:election) { create_election_with_participants.first }
      let(:first_candidate) { election.participants.order(:id).first }
      let(:second_candidate) { election.participants.order(:id).second }

      it "calculates percentages correctly" do
        3.times { service.vote!(participant_id: first_candidate.id) }
        service.vote!(participant_id: second_candidate.id)

        result = ResultsService.new(redis: REDIS).current_results(election)

        expect(result[:total_votes]).to eq(4)
        expect(result[:candidates].find { |c| c[:participant_id] == first_candidate.id }[:percentage]).to eq(75.0)
        expect(result[:candidates].find { |c| c[:participant_id] == second_candidate.id }[:percentage]).to eq(25.0)
      end
    end
  end
end
