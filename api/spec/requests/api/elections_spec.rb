require "rails_helper"

RSpec.describe "Api::Elections", type: :request do
  describe "GET /api/elections/current" do
    it "returns nil when there is no election" do
      get "/api/elections/current"

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("null")
    end

    it "returns draft or running election with participants" do
      election, participants = create_election_with_participants(status: :running)

      get "/api/elections/current"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["id"]).to eq(election.id)
      expect(body["status"]).to eq("running")
      expect(body["participants"].map { |p| p["id"] }).to match_array(participants.map(&:id))
    end
  end

  describe "GET /api/elections/current/results" do
    it "returns empty results when there is no election" do
      get "/api/elections/current/results"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "election_id" => nil,
        "status" => "none",
        "total_votes" => 0,
        "candidates" => []
      )
    end

    it "returns votes per participant when there is an election" do
      election, participants = create_election_with_participants(status: :running)

      REDIS.incr("election:#{election.id}:participant:#{participants[0].id}:votes")
      REDIS.incr("election:#{election.id}:participant:#{participants[1].id}:votes")
      REDIS.incr("election:#{election.id}:participant:#{participants[1].id}:votes")

      get "/api/elections/current/results"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["election_id"]).to eq(election.id)
      expect(body["total_votes"]).to eq(3)

      first = body["candidates"].find { |c| c["participant_id"] == participants[0].id }
      second = body["candidates"].find { |c| c["participant_id"] == participants[1].id }
      expect(first["votes"]).to eq(1)
      expect(second["votes"]).to eq(2)
    end
  end

  describe "GET /api/elections/current/hourly" do
    it "returns empty hours when there is no data" do
      create_election_with_participants(status: :running)

      get "/api/elections/current/hourly"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["hours"]).to eq([])
    end

    it "returns hourly data when Redis has keys" do
      election, = create_election_with_participants(status: :running)

      REDIS.incr("election:#{election.id}:hour:2026-07-06T20:00:00Z:votes")
      REDIS.incr("election:#{election.id}:hour:2026-07-06T21:00:00Z:votes")

      get "/api/elections/current/hourly"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["hours"]).to eq(
        [
          { "hour" => "2026-07-06T20:00:00Z", "total_votes" => 1 },
          { "hour" => "2026-07-06T21:00:00Z", "total_votes" => 1 }
        ]
      )
    end
  end
end
