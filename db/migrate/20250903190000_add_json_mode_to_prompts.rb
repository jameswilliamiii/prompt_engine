class AddJsonModeToPrompts < ActiveRecord::Migration[8.0]
  def change
    add_column :prompt_engine_prompts, :json_mode, :boolean, default: false, null: false
    add_column :prompt_engine_prompt_versions, :json_mode, :boolean, default: false, null: false
    add_index :prompt_engine_prompts, :json_mode
    add_index :prompt_engine_prompt_versions, :json_mode
  end
end
