require "rails_helper"

RSpec.describe "Metrics", type: :request do
  describe "GET /metrics" do
    it "returns 200" do
      get "/metrics"

      expect(response).to have_http_status(:ok)
    end

    it "returns Prometheus text format" do
      get "/metrics"

      expect(response.content_type).to include("text/plain")
      expect(response.body).to include("http_requests_total")
      expect(response.body).to include("votes_total")
      expect(response.body).to include("current_election_total_votes")
    end
  end
end
