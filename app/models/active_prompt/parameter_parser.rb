module ActivePrompt
  class ParameterParser
    attr_reader :content

    def initialize(content)
      @content = content
    end

    def extract_parameters
      return [] if content.blank?

      parameter_names = content.scan(/\{\{([^}]+)\}\}/).flatten.map(&:strip).uniq

      parameter_names.map do |name|
        {
          name: name,
          placeholder: "{{#{name}}}",
          required: true
        }
      end
    end

    def replace_parameters(parameters = {})
      result = content.dup

      return result if parameters.nil?

      parameters.each do |key, value|
        result.gsub!("{{#{key}}}", value.to_s)
      end

      result
    end

    def has_parameters?
      extract_parameters.any?
    end
  end
end
