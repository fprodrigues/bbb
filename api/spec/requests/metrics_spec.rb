require "rails_helper"

RSpec.describe "Metrics", type: :request do
  describe "GET /metrics" do
    it "returns Prometheus metrics as plain text" do
      get "/metrics"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to include("http_requests_total")
      expect(response.body).to include("votes_total")
      expect(response.body).to include("votes_rejected_total")
    end
  end
end
