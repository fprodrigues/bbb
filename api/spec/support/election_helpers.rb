module ElectionHelpers
  def create_election_with_participants(status: :draft, participant_count: 2)
    election = create(:election, status)
    participants = create_list(:participant, participant_count)

    participants.each do |participant|
      create(:election_participant, election: election, participant: participant)
    end

    [election.reload, participants]
  end
end

RSpec.configure do |config|
  config.include ElectionHelpers
end
