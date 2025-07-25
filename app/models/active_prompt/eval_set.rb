module ActivePrompt
  class EvalSet < ApplicationRecord
    belongs_to :prompt
    has_many :test_cases, dependent: :destroy
    has_many :eval_runs, dependent: :destroy
    
    validates :name, presence: true
    validates :name, uniqueness: { scope: :prompt_id }
    
    scope :by_name, -> { order(:name) }
    scope :with_test_cases, -> { includes(:test_cases) }
    
    def latest_run
      eval_runs.recent.first
    end
    
    def average_success_rate
      runs_with_results = eval_runs.completed.where("total_count > 0")
      return 0 if runs_with_results.empty?
      
      total_passed = runs_with_results.sum(:passed_count)
      total_count = runs_with_results.sum(:total_count)
      
      return 0 if total_count.zero?
      (total_passed.to_f / total_count * 100).round(1)
    end
    
    def ready_to_run?
      test_cases.any?
    end
  end
end