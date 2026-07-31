class AddCancellationMetadataToSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :sessions, :cancellation_reason, :string
    add_column :sessions, :cancelled_at, :datetime
  end
end