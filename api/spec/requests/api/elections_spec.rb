require "rails_helper"

RSpec.describe "Api::Elections", type: :request do
  describe "GET /api/elections/current" do
    it "returns null when there is no election" do
      get "/api/elections/current"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_nil
    end

    it "returns draft or running election with participants" do
      election, participants = create_election_with_participants(status: :draft)

      get "/api/elections/current"

      body = JSON.parse(response.body)
      expect(body["id"]).to eq(election.id)
      expect(body["status"]).to eq("draft")
      expect(body["participants"].map { |p| p["id"] }).to match_array(participants.map(&:id))
    end
  end

  describe "GET /api/elections/current/results" do
    it "returns empty results when there is no election" do
      get "/api/elections/current/results"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        "election_id" => nil,
        "status" => "none",
        "total_votes" => 0,
        "candidates" => []
      )
    end

    it "returns votes per participant when there is an election" do
      election, participants = create_election_with_participants
      REDIS.incr(vote_key(election.id, participants.first.id))

      get "/api/elections/current/results"

      body = JSON.parse(response.body)
      expect(body["election_id"]).to eq(election.id)
      expect(body["total_votes"]).to eq(1)
      expect(body["candidates"].size).to eq(2)
    end
  end

  describe "GET /api/elections/current/hourly" do
    it "returns empty hours when there is no data" do
      create_election_with_participants

      get "/api/elections/current/hourly"

      body = JSON.parse(response.body)
      expect(body["hours"]).to eq([])
    end

    it "returns hourly data when Redis has keys" do
      election, = create_election_with_participants
      hour = Time.current.beginning_of_hour.utc.iso8601
      REDIS.incr(hour_key(election.id, hour))

      get "/api/elections/current/hourly"

      body = JSON.parse(response.body)
      expect(body["election_id"]).to eq(election.id)
      expect(body["hours"]).to eq([{ "hour" => hour, "total_votes" => 1 }])
    end
  end
end
