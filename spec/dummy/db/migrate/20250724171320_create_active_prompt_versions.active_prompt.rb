# This migration comes from active_prompt (originally 20250723184757)
class CreateActivePromptVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :active_prompt_prompt_versions do |t|
      t.references :prompt, null: false, foreign_key: { to_table: :active_prompt_prompts }
      t.integer :version_number, null: false
      t.text :content, null: false
      t.text :system_message
      t.string :model
      t.float :temperature
      t.integer :max_tokens
      t.json :metadata
      t.string :created_by
      t.text :change_description

      t.timestamps
    end

    add_index :active_prompt_prompt_versions, [ :prompt_id, :version_number ], unique: true, name: 'index_prompt_versions_on_prompt_and_version'
    add_index :active_prompt_prompt_versions, :version_number

    # Add version_count counter cache to prompts table
    add_column :active_prompt_prompts, :versions_count, :integer, default: 0, null: false
  end
end
