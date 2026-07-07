module Api
  class VotesController < ApplicationController
    rescue_from VotingService::NoRunningElectionError, with: :unprocessable_entity
    rescue_from VotingService::InvalidParticipantError, with: :unprocessable_entity

    def create
      result = VotingService.new.vote!(
        participant_id: params.require(:participant_id)
      )

      render json: result, status: :created
    end

    private

    def unprocessable_entity(error)
      Rails.logger.error(
        event: "vote_error",
        error: error.message
      ).to_json

      render json: { error: error.message }, status: :unprocessable_entity
    end
  end
end