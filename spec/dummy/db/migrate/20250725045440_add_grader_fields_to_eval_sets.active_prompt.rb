# This migration comes from active_prompt (originally 20250125000001)
class AddGraderFieldsToEvalSets < ActiveRecord::Migration[7.1]
  def change
    add_column :active_prompt_eval_sets, :grader_type, :string, default: 'exact_match', null: false
    add_column :active_prompt_eval_sets, :grader_config, :json, default: {}
    
    add_index :active_prompt_eval_sets, :grader_type
  end
end