require "rails_helper"

RSpec.describe "Api::Votes", type: :request do
  describe "POST /api/votes" do
    let!(:election) { create(:election, :running) }
    let!(:first_participant) { create(:participant) }
    let!(:second_participant) { create(:participant) }

    before do
      create(:election_participant, election: election, participant: first_participant)
      create(:election_participant, election: election, participant: second_participant)
    end

    it "returns 201 with updated results for a valid vote" do
      post "/api/votes", params: { participant_id: first_participant.id }

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["election_id"]).to eq(election.id)
      expect(body["total_votes"]).to eq(1)
      expect(body["candidates"].find { |c| c["participant_id"] == first_participant.id }["votes"]).to eq(1)
    end

    it "returns 422 when there is no running election" do
      election.update!(status: "closed", ended_at: Time.current)

      post "/api/votes", params: { participant_id: first_participant.id }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Nenhuma votação em andamento.")
    end

    it "returns 422 when participant is not in the running election" do
      outsider = create(:participant)

      post "/api/votes", params: { participant_id: outsider.id }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Participante não disponível para esta votação.")
    end
  end
end
