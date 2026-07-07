class ElectionClosingService
  def initialize(redis: REDIS)
    @redis = redis
  end

  def close!(election)
    raise "Votação não está em andamento." unless election.running?

    ActiveRecord::Base.transaction do
      persist_final_votes(election)
      persist_hourly_snapshots(election)

      election.update!(
        status: "closed",
        ended_at: Time.current
      )
    end

    Rails.logger.info(
      event: "election_closed",
      election_id: election.id
    ).to_json

    election
  end

  private

  def persist_final_votes(election)
    election.election_participants.includes(:participant).find_each do |election_participant|
      votes = @redis.get(
        "election:#{election.id}:participant:#{election_participant.participant_id}:votes"
      ).to_i

      election_participant.update!(final_votes: votes)
    end
  end

  def persist_hourly_snapshots(election)
    pattern = "election:#{election.id}:hour:*:votes"

    @redis.keys(pattern).each do |key|
      hour = key.split(":hour:").last.delete_suffix(":votes")
      votes = @redis.get(key).to_i

      election.participants.each do |participant|
        participant_votes = @redis.get(
          "election:#{election.id}:participant:#{participant.id}:votes"
        ).to_i

        VoteSnapshot.find_or_initialize_by(
          election: election,
          participant: participant,
          hour: Time.zone.parse(hour)
        ).tap do |snapshot|
          snapshot.votes = participant_votes
          snapshot.save!
        end
      end
    end
  end
end