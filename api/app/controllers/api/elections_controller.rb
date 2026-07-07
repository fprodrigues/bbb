module Api
  class ElectionsController < ApplicationController
    def current
      election = Election.current.first

      if election
        render json: election_payload(election)
      else
        render json: nil
      end
    end

    def results
      render json: ResultsService.new.current_results
    end

    def hourly
      render json: ResultsService.new.hourly_results
    end

    private

    def election_payload(election)
      {
        id: election.id,
        status: election.status,
        started_at: election.started_at,
        ended_at: election.ended_at,
        participants: election.participants.as_json(
          only: [:id, :name, :avatar_url, :active]
        )
      }
    end
  end
end