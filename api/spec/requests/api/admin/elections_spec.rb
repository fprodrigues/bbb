require "rails_helper"

RSpec.describe "Api::Admin::Elections", type: :request do
  describe "POST /api/admin/elections" do
    let!(:first_participant) { create(:participant) }
    let!(:second_participant) { create(:participant) }
    let!(:third_participant) { create(:participant) }

    it "creates a draft election with exactly 2 participants" do
      post "/api/admin/elections", params: {
        participant_ids: [first_participant.id, second_participant.id]
      }

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["status"]).to eq("draft")
      expect(body["participants"].size).to eq(2)
      expect(Election.last.draft?).to be(true)
    end

    it "rejects fewer than 2 participants" do
      post "/api/admin/elections", params: { participant_ids: [first_participant.id] }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Selecione exatamente 2 participantes.")
    end

    it "rejects more than 2 participants" do
      post "/api/admin/elections", params: {
        participant_ids: [first_participant.id, second_participant.id, third_participant.id]
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Selecione exatamente 2 participantes.")
    end

    it "rejects creating another election when draft or running already exists" do
      create(:election, :draft)

      post "/api/admin/elections", params: {
        participant_ids: [first_participant.id, second_participant.id]
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Já existe uma votação criada ou em andamento.")
    end
  end

  describe "POST /api/admin/elections/:id/start" do
    it "starts a draft election" do
      election, = create_election_with_participants(status: :draft)

      freeze_time do
        post "/api/admin/elections/#{election.id}/start"

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body["status"]).to eq("running")
        expect(body["started_at"]).to eq(Time.current.as_json)
        expect(election.reload.running?).to be(true)
      end
    end

    it "rejects starting when election is not draft" do
      election, = create_election_with_participants(status: :running)

      post "/api/admin/elections/#{election.id}/start"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("A votação precisa estar em draft para ser iniciada.")
    end
  end

  describe "POST /api/admin/elections/:id/close" do
    it "closes a running election and persists final votes" do
      election, participants = create_election_with_participants(status: :running)

      REDIS.incr("election:#{election.id}:participant:#{participants[0].id}:votes")
      REDIS.incr("election:#{election.id}:participant:#{participants[0].id}:votes")
      REDIS.incr("election:#{election.id}:participant:#{participants[1].id}:votes")

      freeze_time do
        hour = Time.current.beginning_of_hour.utc.iso8601
        REDIS.incr("election:#{election.id}:hour:#{hour}:votes")
        REDIS.incr("election:#{election.id}:hour:#{hour}:votes")
        REDIS.incr("election:#{election.id}:hour:#{hour}:votes")

        post "/api/admin/elections/#{election.id}/close"

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body["status"]).to eq("closed")
        expect(body["ended_at"]).to eq(Time.current.as_json)
        expect(election.reload.closed?).to be(true)

        first_ep = election.election_participants.find_by(participant: participants[0])
        second_ep = election.election_participants.find_by(participant: participants[1])
        expect(first_ep.final_votes).to eq(2)
        expect(second_ep.final_votes).to eq(1)
      end
    end
  end

  describe "GET /api/admin/elections/history" do
    it "returns closed elections with totals and participant percentages" do
      election = create(:election, :closed)
      first_participant = create(:participant, name: "A")
      second_participant = create(:participant, name: "B")
      create(:election_participant, election: election, participant: first_participant, final_votes: 3)
      create(:election_participant, election: election, participant: second_participant, final_votes: 1)

      get "/api/admin/elections/history"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body.size).to eq(1)

      history = body.first
      expect(history["id"]).to eq(election.id)
      expect(history["status"]).to eq("closed")
      expect(history["total_votes"]).to eq(4)

      first = history["participants"].find { |p| p["participant_id"] == first_participant.id }
      second = history["participants"].find { |p| p["participant_id"] == second_participant.id }
      expect(first["votes"]).to eq(3)
      expect(first["percentage"]).to eq(75.0)
      expect(second["votes"]).to eq(1)
      expect(second["percentage"]).to eq(25.0)
    end
  end
end
