class AddOpenAiFieldsToEvals < ActiveRecord::Migration[7.1]
  def change
    add_column :active_prompt_eval_sets, :openai_eval_id, :string
    add_column :active_prompt_eval_runs, :openai_run_id, :string
    add_column :active_prompt_eval_runs, :openai_file_id, :string
    add_column :active_prompt_eval_runs, :report_url, :string
    
    add_index :active_prompt_eval_sets, :openai_eval_id
    add_index :active_prompt_eval_runs, :openai_run_id
  end
end