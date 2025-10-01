module PromptEngine
  class RenderedPrompt
    attr_reader :prompt, :content, :overrides,
                :version_number

    def initialize(prompt, rendered_data, overrides = {})
      @prompt = prompt
      @content = rendered_data[:content]
      @parameters = rendered_data[:parameters_used] || {}
      @overrides = overrides
      @version_number = rendered_data[:version_number]
      @rendered_data = rendered_data

      # Store status - use override if provided, otherwise use prompt's current status
      # Note: When a specific version is loaded, we still use the current prompt status
      # unless explicitly overridden
      @status = overrides.key?(:status) ? overrides[:status] : prompt.status
    end

    # Options accessor - returns the options hash used for rendering
    def options
      @overrides.dup
    end

    # Individual accessors for common options
    def status
      @status
    end

    def version
      @version_number
    end

    def model
      @overrides[:model] || @rendered_data[:model]
    end

    def temperature
      @overrides[:temperature] || @rendered_data[:temperature]
    end

    def max_tokens
      @overrides[:max_tokens] || @rendered_data[:max_tokens]
    end

    def json_mode
      @overrides.key?(:json_mode) ? @overrides[:json_mode] : @rendered_data[:json_mode] || prompt.json_mode
    end

    def system_message
      @overrides[:system_message] || @rendered_data[:system_message]
    end

    # Returns messages array for chat-based models
    def messages
      msgs = []
      msgs << { role: "system", content: system_message } if system_message.present?
      
      # Ensure JSON instruction is present when json_mode is enabled
      user_content = content
      if json_mode && !user_content.downcase.include?('json')
        user_content = "#{user_content}\n\nPlease respond with valid JSON format."
      end
      
      msgs << { role: "user", content: user_content }
      msgs
    end

    # For OpenAI gem compatibility
    def to_openai_params(**additional_options)
      base_params = {
        model: model || "gpt-4",
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens
      }.compact

      # Merge with additional options (tools, functions, response_format, etc.)
      base_params.merge(additional_options)
    end

    # For RubyLLM compatibility
    def to_ruby_llm_params(**additional_options)
      base_params = {
        messages: messages,
        model: model || "gpt-4",
        temperature: temperature,
        max_tokens: max_tokens
      }.compact

      # If json_mode enabled and no explicit response_format passed, add it
      if json_mode && !additional_options.key?(:response_format)
        additional_options = additional_options.merge(response_format: { type: "json_object" })
      end

      base_params.merge(additional_options)
    end

    # Automatic client detection and execution
    def execute_with(client, **options)
      case client.class.name
      when /OpenAI/
        params = to_openai_params(**options)
        client.chat(parameters: params)
      when /RubyLLM/, /Anthropic/
        params = to_ruby_llm_params(**options)
        client.chat(**params)
      else
        raise ArgumentError, "Unknown client type: #{client.class.name}"
      end
    end

    # Parameter access methods
    def parameters
      @parameters
    end

    def parameter(key)
      @parameters[key.to_s]
    end

    def parameter_names
      @parameters.keys
    end

    def parameter_values
      @parameters.values
    end

    # Check if a parameter exists
    def parameter?(key)
      @parameters.key?(key.to_s)
    end

    # Convenience methods
    def to_h
      {
        content: content,
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        messages: messages,
        options: options,
        status: status,
        version: version,
        parameters: parameters
      }
    end

    def inspect
      version_info = version_number ? " version=#{version_number}" : ""
      param_info = parameter_names.any? ? " parameters=#{parameter_names}" : ""
      override_info = overrides.any? ? " overrides=#{overrides.keys}" : ""
      "#<PromptEngine::RenderedPrompt prompt=#{prompt.slug}#{version_info}#{param_info}#{override_info}>"
    end
  end
end
