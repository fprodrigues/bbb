class VotingService
  class Error < StandardError; end
  class NoRunningElectionError < Error; end
  class InvalidParticipantError < Error; end

  def initialize(redis: REDIS)
    @redis = redis
  end

  def vote!(participant_id:)
    election = Election.running.first
    VOTES_REJECTED_TOTAL.increment(labels: { reason: "no_running_election" })
    raise NoRunningElectionError, "Nenhuma votação em andamento." unless election

    participant_id = participant_id.to_i

    unless election.participants.exists?(id: participant_id)
      Rails.logger.warn(
        event: "invalid_vote",
        election_id: election.id,
        participant_id: participant_id
      ).to_json

      VOTES_REJECTED_TOTAL.increment(labels: { reason: "invalid_participant" })
      raise InvalidParticipantError, "Participante não disponível para esta votação."
    end

    @redis.multi do |transaction|
      transaction.incr(vote_key(election.id, participant_id))
      transaction.incr(total_key(election.id))
      transaction.incr(hour_key(election.id, current_hour))
    end

    VOTES_TOTAL.increment(labels: { participant_id: participant_id.to_s })

    Rails.logger.info(
      event: "vote_computed",
      election_id: election.id,
      participant_id: participant_id
    ).to_json

    ResultsService.new(redis: @redis).current_results(election)
  end

  private

  def current_hour
    Time.current.beginning_of_hour.utc.iso8601
  end

  def vote_key(election_id, participant_id)
    "election:#{election_id}:participant:#{participant_id}:votes"
  end

  def total_key(election_id)
    "election:#{election_id}:total_votes"
  end

  def hour_key(election_id, hour)
    "election:#{election_id}:hour:#{hour}:votes"
  end
end