class CreateElections < ActiveRecord::Migration[7.1]
  def change
    create_table :elections do |t|
      t.string :status, null: false, default: "draft"
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end

    add_index :elections, :status
  end
end