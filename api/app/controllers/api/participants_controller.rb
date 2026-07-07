module Api
  class ParticipantsController < ApplicationController
    def index
      participants = Participant.where(active: true).order(:name)

      render json: participants.as_json(
        only: [:id, :name, :avatar_url, :active]
      )
    end
  end
end