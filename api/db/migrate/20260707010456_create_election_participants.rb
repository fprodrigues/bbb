class CreateElectionParticipants < ActiveRecord::Migration[7.1]
  def change
    create_table :election_participants do |t|
      t.references :election, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true
      t.integer :final_votes, null: false, default: 0

      t.timestamps
    end

    add_index :election_participants,
              [:election_id, :participant_id],
              unique: true,
              name: "idx_election_participant_unique"
  end
end