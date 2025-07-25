module ActivePrompt
  class EvalResult < ApplicationRecord
    belongs_to :eval_run
    belongs_to :test_case
  end
end