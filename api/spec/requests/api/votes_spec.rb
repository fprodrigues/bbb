require "rails_helper"

RSpec.describe "Api::Votes", type: :request do
  describe "POST /api/votes" do
    context "with a valid vote" do
      it "returns 201 with updated results" do
        _election, participants = create_election_with_participants

        post "/api/votes", params: { participant_id: participants.first.id }

        expect(response).to have_http_status(:created)

        body = JSON.parse(response.body)
        expect(body["total_votes"]).to eq(1)
        expect(body["candidates"].find { |c| c["participant_id"] == participants.first.id }["votes"]).to eq(1)
      end
    end

    context "when there is no running election" do
      it "returns 422" do
        post "/api/votes", params: { participant_id: 1 }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Nenhuma votação em andamento.")
      end
    end

    context "when participant is not in the running election" do
      it "returns 422" do
        create_election_with_participants
        outsider = create(:participant, name: "Fora")

        post "/api/votes", params: { participant_id: outsider.id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Participante não disponível para esta votação.")
      end
    end
  end
end
