module ActivePrompt
  class EvalRun < ApplicationRecord
    belongs_to :eval_set
    belongs_to :prompt_version
    has_many :eval_results, dependent: :destroy
    
    enum status: { pending: 0, running: 1, completed: 2, failed: 3 }
  end
end