module ActivePrompt
  class PlaygroundRunResult < ApplicationRecord
    self.table_name = "active_prompt_playground_run_results"

    belongs_to :prompt_version, class_name: "ActivePrompt::PromptVersion"

    validates :provider, presence: true
    validates :model, presence: true
    validates :rendered_prompt, presence: true
    validates :response, presence: true
    validates :execution_time, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :token_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    serialize :parameters, coder: JSON

    scope :recent, -> { order(created_at: :desc) }
    scope :by_provider, ->(provider) { where(provider: provider) }
    scope :successful, -> { where.not(response: nil) }
  end
end
