class CreateRegistrations < ActiveRecord::Migration[7.2]
  ACTIVE_REGISTRATION_STATUSES = %w[held confirmed waitlisted].freeze

  def change
    create_table :registrations do |t|
      t.references :attendee, null: false, foreign_key: true
      t.references :session, null: false, foreign_key: true
      t.string :status, null: false
      t.datetime :hold_expires_at
      t.datetime :confirmed_at
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :registrations, :status
    add_index :registrations, [:attendee_id, :session_id],
      unique: true,
      where: "status IN ('#{ACTIVE_REGISTRATION_STATUSES.join("', '")}')",
      name: "index_registrations_on_active_attendee_session"
  end
end
