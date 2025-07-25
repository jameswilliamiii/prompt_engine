module ActivePrompt
  class EvalSet < ApplicationRecord
    belongs_to :prompt
    has_many :test_cases, dependent: :destroy
    has_many :eval_runs, dependent: :destroy
    
    GRADER_TYPES = {
      exact_match: "Exact Match",
      regex: "Regular Expression",
      contains: "Contains Text",
      json_schema: "JSON Match (Exact)"
    }.freeze
    
    validates :name, presence: true
    validates :name, uniqueness: { scope: :prompt_id }
    validates :grader_type, presence: true, inclusion: { in: GRADER_TYPES.keys.map(&:to_s) }
    
    validate :validate_grader_config
    
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
    
    def grader_type_display
      GRADER_TYPES[grader_type.to_sym] || grader_type.humanize
    end
    
    def requires_grader_config?
      %w[regex json_schema].include?(grader_type)
    end
    
    private
    
    def validate_grader_config
      return unless requires_grader_config?
      
      case grader_type
      when 'regex'
        validate_regex_config
      when 'json_schema'
        validate_json_schema_config
      end
    end
    
    def validate_regex_config
      pattern = grader_config['pattern']
      
      if pattern.blank?
        errors.add(:grader_config, "regex pattern is required")
        return
      end
      
      begin
        Regexp.new(pattern)
      rescue RegexpError => e
        errors.add(:grader_config, "invalid regex pattern: #{e.message}")
      end
    end
    
    def validate_json_schema_config
      schema = grader_config['schema']
      
      if schema.blank?
        errors.add(:grader_config, "JSON schema is required")
        return
      end
      
      begin
        JSON.parse(schema.to_json) if schema.is_a?(Hash)
        # Basic schema validation - check for required fields
        unless schema.is_a?(Hash) && schema['type'].present?
          errors.add(:grader_config, "JSON schema must include a 'type' field")
        end
      rescue JSON::ParserError => e
        errors.add(:grader_config, "invalid JSON schema: #{e.message}")
      end
    end
  end
end