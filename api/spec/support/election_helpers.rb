module ElectionHelpers
  def create_election_with_participants(status: :running, participants: nil)
    participants ||= [
      create(:participant, name: "Candidato A"),
      create(:participant, name: "Candidato B")
    ]

    election = create(:election, status)
    participants.each do |participant|
      create(:election_participant, election: election, participant: participant)
    end

    [election, participants]
  end

  def vote_key(election_id, participant_id)
    "election:#{election_id}:participant:#{participant_id}:votes"
  end

  def total_key(election_id)
    "election:#{election_id}:total_votes"
  end

  def hour_key(election_id, hour = Time.current.beginning_of_hour.utc.iso8601)
    "election:#{election_id}:hour:#{hour}:votes"
  end
end

RSpec.configure do |config|
  config.include ElectionHelpers
end
