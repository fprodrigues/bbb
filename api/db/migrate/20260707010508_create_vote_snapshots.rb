class CreateVoteSnapshots < ActiveRecord::Migration[7.1]
  def change
    create_table :vote_snapshots do |t|
      t.references :election, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true
      t.integer :votes, null: false, default: 0
      t.datetime :hour, null: false

      t.timestamps
    end

    add_index :vote_snapshots,
              [:election_id, :participant_id, :hour],
              unique: true,
              name: "idx_vote_snapshots_unique"
  end
end