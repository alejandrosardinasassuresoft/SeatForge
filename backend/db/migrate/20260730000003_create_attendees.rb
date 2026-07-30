class CreateAttendees < ActiveRecord::Migration[7.2]
  def change
    create_table :attendees do |t|
      t.string :name, null: false
      t.string :email, null: false

      t.timestamps
    end

    add_index :attendees, "LOWER(email)", unique: true, name: "index_attendees_on_lower_email"
  end
end
