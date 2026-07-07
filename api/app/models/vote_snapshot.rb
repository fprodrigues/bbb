class VoteSnapshot < ApplicationRecord
  belongs_to :election
  belongs_to :participant

  validates :hour, presence: true
end
