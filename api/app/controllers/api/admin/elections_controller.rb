module Api
  module Admin
    class ElectionsController < ApplicationController
      def create
        participant_ids = params.require(:participant_ids)

        if participant_ids.size != 2
          return render json: {
            error: "Selecione exatamente 2 participantes."
          }, status: :unprocessable_entity
        end

        if Election.where(status: %w[draft running]).exists?
          return render json: {
            error: "Já existe uma votação criada ou em andamento."
          }, status: :unprocessable_entity
        end

        election = nil

        ActiveRecord::Base.transaction do
          election = Election.create!(status: "draft")

          participant_ids.each do |participant_id|
            election.election_participants.create!(
              participant_id: participant_id
            )
          end
        end

        Rails.logger.info(
          event: "election_created",
          election_id: election.id,
          participant_ids: participant_ids
        ).to_json

        render json: election_payload(election), status: :created
      end

      def start
        election = Election.find(params[:id])

        unless election.draft?
          return render json: {
            error: "A votação precisa estar em draft para ser iniciada."
          }, status: :unprocessable_entity
        end

        election.update!(
          status: "running",
          started_at: Time.current
        )

        Rails.logger.info(
          event: "election_started",
          election_id: election.id
        ).to_json

        render json: election_payload(election)
      end

      def close
        election = Election.find(params[:id])
        closed_election = ElectionClosingService.new.close!(election)

        render json: election_payload(closed_election)
      rescue StandardError => error
        Rails.logger.error(
          event: "close_election_error",
          error: error.message
        ).to_json

        render json: { error: error.message }, status: :unprocessable_entity
      end

      def history
        elections = Election.closed.includes(:participants, :election_participants)

        render json: elections.map { |election| history_payload(election) }
      end

      private

      def election_payload(election)
        election.reload

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

      def history_payload(election)
        election_participants = election.election_participants.includes(:participant)
        total_votes = election_participants.sum(:final_votes)

        participants = election_participants.map do |ep|
          percentage =
            if total_votes.positive?
              ((ep.final_votes.to_f / total_votes) * 100).round(2)
            else
              0.0
            end

          {
            participant_id: ep.participant_id,
            name: ep.participant&.name,
            votes: ep.final_votes,
            percentage: percentage
          }
        end

        {
          id: election.id,
          status: election.status,
          started_at: election.started_at,
          ended_at: election.ended_at,
          total_votes: total_votes,
          participants: participants
        }
      end
    end
  end
end