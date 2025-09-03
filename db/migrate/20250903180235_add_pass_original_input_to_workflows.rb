class AddPassOriginalInputToWorkflows < ActiveRecord::Migration[8.0]
  def change
    add_column :prompt_engine_workflows, :pass_original_input, :boolean, default: true, null: false
  end
end
