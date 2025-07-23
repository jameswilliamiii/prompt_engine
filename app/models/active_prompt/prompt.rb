module ActivePrompt
  class Prompt < ApplicationRecord
    self.table_name = "active_prompt_prompts"
    
    has_many :versions, -> { order(version_number: :desc) }, 
             class_name: 'ActivePrompt::PromptVersion',
             dependent: :destroy
    has_many :parameters, -> { ordered }, 
             class_name: 'ActivePrompt::Parameter',
             dependent: :destroy
    
    attr_accessor :change_summary

    validates :name, presence: true, uniqueness: { scope: :status }
    validates :content, presence: true
    
    accepts_nested_attributes_for :parameters, allow_destroy: true
    
    enum :status, {
      draft: 'draft',
      active: 'active',
      archived: 'archived'
    }, default: 'draft'
    
    scope :active, -> { where(status: 'active') }
    scope :by_name, -> { order(:name) }

    after_create :create_initial_version
    after_update :create_version_if_changed
    before_save :clean_orphaned_parameters

    VERSIONED_ATTRIBUTES = %w[content system_message model temperature max_tokens metadata].freeze

    def current_version
      versions.first
    end

    def version_count
      versions_count
    end

    def restore_version!(version_number)
      version = versions.find_by!(version_number: version_number)
      version.restore!
    end

    def version_at(version_number)
      versions.find_by(version_number: version_number)
    end

    def versioned_attributes_changed?
      # This method is for checking if versioned attributes have changed before save
      (changed & VERSIONED_ATTRIBUTES).any?
    end
    
    # Parameter management methods
    def detect_variables
      @variable_detector ||= ActivePrompt::VariableDetector.new(content)
      @variable_detector.variable_names
    end
    
    def sync_parameters!
      detected_vars = detect_variables
      existing_names = parameters.pluck(:name)
      
      # Add new parameters
      new_vars = detected_vars - existing_names
      new_vars.each_with_index do |var_name, index|
        detector = ActivePrompt::VariableDetector.new(content)
        var_info = detector.extract_variables.find { |v| v[:name] == var_name }
        
        parameters.create!(
          name: var_name,
          parameter_type: var_info[:type],
          position: parameters.count + index + 1
        )
      end
      
      # Remove parameters that no longer exist
      removed_vars = existing_names - detected_vars
      parameters.where(name: removed_vars).destroy_all if removed_vars.any?
      
      true
    end
    
    def render_with_params(provided_params = {})
      detector = ActivePrompt::VariableDetector.new(content)
      
      # Validate all required parameters are provided
      validation = validate_parameters(provided_params)
      return { error: validation[:errors].join(', ') } unless validation[:valid]
      
      # Cast parameters to their correct types
      casted_params = {}
      parameters.each do |param|
        value = provided_params[param.name] || provided_params[param.name.to_sym]
        casted_params[param.name] = param.cast_value(value)
      end
      
      {
        content: detector.render(casted_params),
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        parameters_used: casted_params
      }
    end
    
    def validate_parameters(provided_params = {})
      errors = []
      
      parameters.each do |param|
        value = provided_params[param.name] || provided_params[param.name.to_sym]
        param_errors = param.validate_value(value)
        errors.concat(param_errors)
      end
      
      {
        valid: errors.empty?,
        errors: errors
      }
    end

    private

    def create_initial_version
      versions.create!(
        content: content,
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        metadata: metadata,
        change_description: 'Initial version'
      )
    end

    def create_version_if_changed
      # Check saved_changes in the after_update callback
      return unless (saved_changes.keys & VERSIONED_ATTRIBUTES).any?

      versions.create!(
        content: content,
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        metadata: metadata,
        change_description: "Updated: #{(saved_changes.keys & VERSIONED_ATTRIBUTES).join(', ')}"
      )
    end
    
    def clean_orphaned_parameters
      return unless content_changed?
      
      # Mark parameters for destruction if their names are not in the content
      detected_vars = detect_variables
      parameters.each do |param|
        param.mark_for_destruction unless detected_vars.include?(param.name)
      end
    end
  end
end
