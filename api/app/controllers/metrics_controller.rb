class MetricsController < ApplicationController
  skip_before_action :track_request_metrics, raise: false

  def index
    update_current_election_metrics

    render plain: Prometheus::Client::Formats::Text.marshal(PROMETHEUS),
           content_type: "text/plain"
  end

  private

  def update_current_election_metrics
    reset_current_election_metrics

    election = Election.running.first

    unless election
      CURRENT_ELECTION_TOTAL_VOTES.set(0)
      return
    end

    results = ResultsService.new.current_results(election)

    CURRENT_ELECTION_TOTAL_VOTES.set(results[:total_votes].to_i)

    results[:candidates].each do |candidate|
      labels = {
        participant_id: candidate[:participant_id].to_s,
        participant_name: candidate[:name].to_s
      }

      CURRENT_ELECTION_PARTICIPANT_VOTES.set(
        candidate[:votes].to_i,
        labels: labels
      )

      CURRENT_ELECTION_PARTICIPANT_ACTIVE.set(
        1,
        labels: labels
      )
    end
  rescue StandardError => error
    Rails.logger.error(
      {
        event: "metrics_current_election_error",
        error: error.message
      }.to_json
    )
  end

  def reset_current_election_metrics
    CURRENT_ELECTION_TOTAL_VOTES.set(0)

    Participant.find_each do |participant|
      labels = {
        participant_id: participant.id.to_s,
        participant_name: participant.name.to_s
      }

      CURRENT_ELECTION_PARTICIPANT_VOTES.set(
        0,
        labels: labels
      )

      CURRENT_ELECTION_PARTICIPANT_ACTIVE.set(
        0,
        labels: labels
      )
    end
  end
end