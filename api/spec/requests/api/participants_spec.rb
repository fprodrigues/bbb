require "rails_helper"

RSpec.describe "Api::Participants", type: :request do
  describe "GET /api/participants" do
    it "returns active participants with expected fields" do
      active = create(:participant, name: "Ativo", avatar_url: "https://example.com/a.png", active: true)
      create(:participant, :inactive, name: "Inativo")

      get "/api/participants"

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first).to eq(
        "id" => active.id,
        "name" => "Ativo",
        "avatar_url" => "https://example.com/a.png",
        "active" => true
      )
    end

    it "does not return inactive participants" do
      create(:participant, :inactive, name: "Inativo")

      get "/api/participants"

      expect(JSON.parse(response.body)).to be_empty
    end
  end
end
