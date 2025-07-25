module ActivePrompt
  class EvalRun < ApplicationRecord
    belongs_to :eval_set
    belongs_to :prompt_version
    has_many :eval_results, dependent: :destroy
    
    enum :status, { pending: 0, running: 1, completed: 2, failed: 3 }
    
    scope :recent, -> { order(created_at: :desc) }
    scope :by_status, ->(status) { where(status: status) }
    scope :successful, -> { completed.where("passed_count > 0") }
    
    def success_rate
      return 0 if total_count.zero?
      (passed_count.to_f / total_count * 100).round(1)
    end
    
    def duration
      return nil unless started_at && completed_at
      completed_at - started_at
    end
    
    def duration_in_words
      return "Not started" unless started_at
      return "Running" if running?
      return "Failed" if failed? && !completed_at
      
      seconds = duration
      return nil unless seconds
      
      if seconds < 60
        "#{seconds.round} seconds"
      elsif seconds < 3600
        "#{(seconds / 60).round} minutes"
      else
        "#{(seconds / 3600).round(1)} hours"
      end
    end
  end
end