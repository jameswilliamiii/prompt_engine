module ActivePrompt
  class EvalSet < ApplicationRecord
    belongs_to :prompt
    has_many :test_cases, dependent: :destroy
    has_many :eval_runs, dependent: :destroy
    
    validates :name, presence: true
  end
end