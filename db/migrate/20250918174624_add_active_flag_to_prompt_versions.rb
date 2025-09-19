class AddActiveFlagToPromptVersions < ActiveRecord::Migration[8.0]
  def change
    add_column :prompt_engine_prompt_versions, :active, :boolean, default: false, null: false unless column_exists?(:prompt_engine_prompt_versions, :active)
    add_index :prompt_engine_prompt_versions, :active unless index_exists?(:prompt_engine_prompt_versions, :active)
  end
end
