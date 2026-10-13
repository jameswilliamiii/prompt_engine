class AddEffortToPromptEngine < ActiveRecord::Migration[8.0]
  def change
    add_column :prompt_engine_prompts, :effort, :string
    add_column :prompt_engine_prompt_versions, :effort, :string
    add_column :prompt_engine_playground_run_results, :effort, :string
  end
end
