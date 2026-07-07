require "rails_helper"

RSpec.describe "Api::Admin::Elections", type: :request do
  describe "POST /api/admin/elections" do
    let(:first_participant) { create(:participant, name: "A") }
    let(:second_participant) { create(:participant, name: "B") }
    let(:third_participant) { create(:participant, name: "C") }

    it "creates a draft election with exactly 2 participants" do
      post "/api/admin/elections", params: {
        participant_ids: [first_participant.id, second_participant.id]
      }

      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)
      expect(body["status"]).to eq("draft")
      expect(body["participants"].map { |p| p["id"] }).to match_array(
        [first_participant.id, second_participant.id]
      )
    end

    it "rejects fewer than 2 participants" do
      post "/api/admin/elections", params: { participant_ids: [first_participant.id] }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Selecione exatamente 2 participantes.")
    end

    it "rejects more than 2 participants" do
      post "/api/admin/elections", params: {
        participant_ids: [first_participant.id, second_participant.id, third_participant.id]
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Selecione exatamente 2 participantes.")
    end

    it "rejects creating another election when draft or running exists" do
      create(:election, :draft)

      post "/api/admin/elections", params: {
        participant_ids: [first_participant.id, second_participant.id]
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Já existe uma votação criada ou em andamento.")
    end
  end

  describe "POST /api/admin/elections/:id/start" do
    it "starts a draft election" do
      election, = create_election_with_participants(status: :draft)
      freeze_time = Time.utc(2026, 7, 7, 16, 0, 0)

      travel_to freeze_time do
        post "/api/admin/elections/#{election.id}/start"
      end

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["status"]).to eq("running")
      expect(Time.zone.parse(body["started_at"])).to eq(freeze_time)
      expect(election.reload.started_at).to eq(freeze_time)
    end

    it "rejects starting when election is not draft" do
      election, = create_election_with_participants

      post "/api/admin/elections/#{election.id}/start"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("A votação precisa estar em draft para ser iniciada.")
    end
  end

  describe "POST /api/admin/elections/:id/close" do
    it "closes a running election and persists final votes" do
      election, participants = create_election_with_participants
      REDIS.incr(vote_key(election.id, participants.first.id))
      REDIS.incr(vote_key(election.id, participants.first.id))
      REDIS.incr(vote_key(election.id, participants.second.id))
      REDIS.incr(hour_key(election.id))

      post "/api/admin/elections/#{election.id}/close"

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["status"]).to eq("closed")
      expect(body["ended_at"]).to be_present
      expect(participants.first.election_participants.find_by(election: election).final_votes).to eq(2)
    end
  end

  describe "GET /api/admin/elections/history" do
    it "returns closed elections with totals and participant percentages" do
      election, participants = create_election_with_participants(status: :closed)
      first_ep = election.election_participants.find_by(participant: participants.first)
      second_ep = election.election_participants.find_by(participant: participants.second)
      first_ep.update!(final_votes: 3)
      second_ep.update!(final_votes: 1)

      get "/api/admin/elections/history"

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first).to include(
        "id" => election.id,
        "status" => "closed",
        "total_votes" => 4
      )
      expect(body.first["participants"]).to contain_exactly(
        hash_including("participant_id" => participants.first.id, "votes" => 3, "percentage" => 75.0),
        hash_including("participant_id" => participants.second.id, "votes" => 1, "percentage" => 25.0)
      )
    end
  end
end
