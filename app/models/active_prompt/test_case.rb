module ActivePrompt
  class TestCase < ApplicationRecord
    belongs_to :eval_set
    has_many :eval_results, dependent: :destroy
    
    validates :input_variables, presence: true
    validates :expected_output, presence: true
  end
end