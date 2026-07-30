class CreateWorkshops < ActiveRecord::Migration[7.2]
  def change
    create_table :workshops do |t|
      t.string :title, null: false
      t.text :description
      t.string :topic, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :workshops, :active
    add_index :workshops, :topic
  end
end
