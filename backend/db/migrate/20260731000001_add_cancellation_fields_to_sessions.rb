class AddCancellationFieldsToSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :sessions, :cancellation_reason, :text
    add_column :sessions, :cancelled_at, :datetime
  end
end
