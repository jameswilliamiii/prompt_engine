class AddToolsToPrompts < ActiveRecord::Migration[8.0]
  def change
    add_column :prompt_engine_prompts, :tools, :json, default: [], null: false
    add_column :prompt_engine_prompt_versions, :tools, :json, default: [], null: false
    add_index :prompt_engine_prompts, :tools, using: :gin
    add_index :prompt_engine_prompt_versions, :tools, using: :gin
  end
end
