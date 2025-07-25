module ActivePrompt
  class TestCase < ApplicationRecord
    belongs_to :eval_set
    has_many :eval_results, dependent: :destroy
    
    validates :input_variables, presence: true
    validates :expected_output, presence: true
    
    scope :by_description, -> { order(:description) }
    
    def display_name
      description.presence || "Test case ##{id}"
    end
    
    def passed_count
      eval_results.where(passed: true).count
    end
    
    def failed_count
      eval_results.where(passed: false).count
    end
    
    def success_rate
      total = eval_results.count
      return 0 if total.zero?
      (passed_count.to_f / total * 100).round(1)
    end
  end
end