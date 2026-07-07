class CreateParticipants < ActiveRecord::Migration[7.1]
  def change
    create_table :participants do |t|
      t.string :name, null: false
      t.string :avatar_url
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :participants, :name, unique: true
  end
end