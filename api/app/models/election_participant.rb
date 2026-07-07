class ElectionParticipant < ApplicationRecord
  belongs_to :election
  belongs_to :participant

  validates :participant_id, uniqueness: { scope: :election_id }
end
