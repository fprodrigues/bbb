class Participant < ApplicationRecord
  has_many :election_participants, dependent: :destroy
  has_many :elections, through: :election_participants

  validates :name, presence: true, uniqueness: true
end
