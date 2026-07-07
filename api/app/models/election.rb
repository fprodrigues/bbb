class Election < ApplicationRecord
  STATUSES = %w[draft running closed].freeze

  has_many :election_participants, dependent: :destroy
  has_many :participants, through: :election_participants
  has_many :vote_snapshots, dependent: :destroy

  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :current, -> { where(status: %w[draft running]).order(created_at: :desc) }
  scope :running, -> { where(status: "running").order(created_at: :desc) }
  scope :closed, -> { where(status: "closed").order(ended_at: :desc) }

  def draft?
    status == "draft"
  end

  def running?
    status == "running"
  end

  def closed?
    status == "closed"
  end
end
