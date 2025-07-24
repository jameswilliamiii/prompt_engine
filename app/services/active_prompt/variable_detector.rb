module ActivePrompt
  class VariableDetector
    # Regex pattern to match {{variable_name}} syntax
    # Allows letters, numbers, underscores, and dots for nested variables
    VARIABLE_PATTERN = /\{\{([a-zA-Z_][a-zA-Z0-9_]*(?:\.[a-zA-Z_][a-zA-Z0-9_]*)*)\}\}/

    attr_reader :content

    def initialize(content)
      @content = content.to_s
    end

    # Extract all variables from the content
    def extract_variables
      variables = []

      content.scan(VARIABLE_PATTERN) do |match|
        variable_name = match.first
        variables << {
          name: variable_name,
          placeholder: "{{#{variable_name}}}",
          position: Regexp.last_match.offset(0),
          type: infer_type(variable_name),
          required: true
        }
      end

      # Remove duplicates while preserving order
      variables.uniq { |v| v[:name] }
    end

    # Get just the variable names as an array
    def variable_names
      extract_variables.map { |v| v[:name] }
    end

    # Check if content contains variables
    def has_variables?
      content.match?(VARIABLE_PATTERN)
    end

    # Count unique variables
    def variable_count
      variable_names.count
    end

    # Replace variables with provided values
    def render(variables = {})
      rendered = content.dup

      variables.each do |key, value|
        # Support both string and symbol keys
        placeholder = "{{#{key}}}"
        rendered.gsub!(placeholder, value.to_s)
      end

      rendered
    end

    # Validate that all required variables are provided
    def validate_variables(provided_variables = {})
      missing = []
      stringified_keys = provided_variables.stringify_keys

      variable_names.each do |var_name|
        unless stringified_keys.key?(var_name)
          missing << var_name
        end
      end

      {
        valid: missing.empty?,
        missing_variables: missing
      }
    end

    private

    # Attempt to infer type from variable name
    def infer_type(variable_name)
      case variable_name.downcase
      when /(_id|_count|_number|_qty|_quantity)$/
        "integer"
      when /(_at|_date|_time)$/
        "datetime"
      when /(_price|_amount|_cost|_total)$/
        "decimal"
      when /(is_|has_|can_|should_)/
        "boolean"
      when /(_list|_array|_items)$/
        "array"
      else
        "string"
      end
    end
  end
end
