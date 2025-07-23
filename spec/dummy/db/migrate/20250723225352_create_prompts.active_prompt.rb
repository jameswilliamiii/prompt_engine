# This migration comes from active_prompt (originally 20250723161909)
class CreatePrompts < ActiveRecord::Migration[8.0]
  def change
    create_table :active_prompt_prompts do |t|
      t.string :name
      t.text :description
      t.text :content
      t.text :system_message
      t.string :model
      t.float :temperature
      t.integer :max_tokens
      t.string :status
      t.json :metadata

      t.timestamps
    end
  end
end
