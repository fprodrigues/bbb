class ResultsService
  def initialize(redis: REDIS)
    @redis = redis
  end

  def current_results(election = Election.current.first)
    return empty_results unless election

    candidates = election.participants.map do |participant|
      votes = votes_for(election.id, participant.id)

      {
        participant_id: participant.id,
        name: participant.name,
        votes: votes,
        percentage: 0.0
      }
    end

    total_votes = candidates.sum { |candidate| candidate[:votes] }

    candidates = candidates.map do |candidate|
      percentage =
        if total_votes.positive?
          ((candidate[:votes].to_f / total_votes) * 100).round(2)
        else
          0.0
        end

      candidate.merge(percentage: percentage)
    end

    {
      election_id: election.id,
      status: election.status,
      total_votes: total_votes,
      candidates: candidates
    }
  end

  def hourly_results(election = Election.current.first)
    return { election_id: nil, hours: [] } unless election

    pattern = "election:#{election.id}:hour:*:votes"

    hours = @redis.keys(pattern).map do |key|
      hour = key.split(":hour:").last.delete_suffix(":votes")

      {
        hour: hour,
        total_votes: @redis.get(key).to_i
      }
    end.sort_by { |item| item[:hour] }

    {
      election_id: election.id,
      hours: hours
    }
  end

  private

  def votes_for(election_id, participant_id)
    @redis.get("election:#{election_id}:participant:#{participant_id}:votes").to_i
  end

  def empty_results
    {
      election_id: nil,
      status: "none",
      total_votes: 0,
      candidates: []
    }
  end
end