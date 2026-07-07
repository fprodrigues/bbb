require "rails_helper"

RSpec.describe "Health", type: :request do
  describe "GET /health" do
    it "returns 200" do
      get "/health"

      expect(response).to have_http_status(:ok)
    end

    it "returns JSON with status ok" do
      get "/health"

      expect(response.content_type).to include("application/json")
      expect(JSON.parse(response.body)).to eq("status" => "ok")
    end
  end
end
