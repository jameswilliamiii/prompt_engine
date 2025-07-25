module PromptEngine
  class EvalResult < ApplicationRecord
    belongs_to :eval_run
    belongs_to :test_case
    
    scope :passed, -> { where(passed: true) }
    scope :failed, -> { where(passed: false) }
    scope :by_execution_time, -> { order(:execution_time_ms) }
    
    def execution_time_seconds
      return nil unless execution_time_ms
      execution_time_ms / 1000.0
    end
    
    def status
      passed? ? "passed" : "failed"
    end
  end
end