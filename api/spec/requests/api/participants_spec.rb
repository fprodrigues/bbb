require "rails_helper"

RSpec.describe "Api::Participants", type: :request do
  describe "GET /api/participants" do
    it "returns active participants with expected fields" do
      active = create(:participant, name: "Ativo", active: true)
      create(:participant, :inactive, name: "Inativo")

      get "/api/participants"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        [
          {
            "id" => active.id,
            "name" => "Ativo",
            "avatar_url" => active.avatar_url,
            "active" => true
          }
        ]
      )
    end
  end
end
