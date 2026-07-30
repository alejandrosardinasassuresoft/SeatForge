class CreateSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :sessions do |t|
      t.references :workshop, null: false, foreign_key: true
      t.integer :capacity, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :status, null: false, default: "scheduled"

      t.timestamps
    end

    add_index :sessions, :status
    add_index :sessions, :starts_at
  end
end
