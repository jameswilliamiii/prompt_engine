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
      return unless PromptEngine.config.supports_temperature?(model)

      @overrides[:temperature] || @rendered_data[:temperature]
    end

    def effort
      return unless PromptEngine.config.supports_effort?(model)

      @overrides[:effort] || @rendered_data[:effort]
    end

    def max_tokens
      @overrides[:max_tokens] || @rendered_data[:max_tokens]
    end

    def system_message
      @overrides[:system_message] || @rendered_data[:system_message]
    end

    # Returns messages array for chat-based models
    def messages
      msgs = []
      msgs << { role: "system", content: system_message } if system_message.present?
      msgs << { role: "user", content: content }
      msgs
    end

    # For OpenAI gem compatibility
    def to_openai_params(**additional_options)
      base_params = {
        model: model,
        messages: messages,
        temperature: temperature,
        max_tokens_key => max_tokens
      }.compact

      # Merge with additional options (tools, functions, response_format, etc.)
      base_params.merge(additional_options)
    end

    # For RubyLLM compatibility
    def to_ruby_llm_params(**additional_options)
      base_params = {
        messages: messages,
        model: model,
        temperature: temperature,
        max_tokens_key => max_tokens,
        output_config: effort && { effort: effort }
      }.compact

      # Merge with additional options
      base_params.merge(additional_options)
    end

    # Builds a RubyLLM chat with the system message and settings applied, ready for #ask.
    # client is the RubyLLM module or a RubyLLM::Context.
    def to_ruby_llm_chat(client = nil, **additional_options)
      require "ruby_llm"

      chat = new_ruby_llm_chat(client || RubyLLM)
      chat = chat.with_instructions(system_message) if system_message.present?
      # with_temperature, not params, so ruby_llm can adjust it for models with fixed temperatures.
      chat = chat.with_temperature(temperature) unless temperature.nil?
      chat.with_params(**to_ruby_llm_params(**additional_options).except(:messages, :model, :temperature))
    end

    # Automatic client detection and execution
    def execute_with(client, **options)
      if ruby_llm_client?(client)
        to_ruby_llm_chat(client, **options).ask(content)
      elsif defined?(RubyLLM::Provider) && client.is_a?(RubyLLM::Provider)
        raise ArgumentError, "Pass RubyLLM or a RubyLLM::Context, not a ruby_llm provider"
      elsif client.class.name.to_s.include?("OpenAI")
        client.chat(parameters: to_openai_params(**options))
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
        effort: effort,
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

    private

    # OpenAI's chat API takes max_completion_tokens; its reasoning models reject max_tokens.
    def max_tokens_key
      PromptEngine.config.provider_for(model) == "openai" ? :max_completion_tokens : :max_tokens
    end

    def ruby_llm_client?(client)
      client.class.name == "RubyLLM::Context" || (client.is_a?(Module) && client.name == "RubyLLM")
    end

    # ruby_llm only knows the models in its registry, so a newer one needs its provider named.
    def new_ruby_llm_chat(client)
      provider = PromptEngine.config.provider_for(model)
      client.chat(model: model, provider: provider)
    rescue RubyLLM::ModelNotFoundError
      raise unless provider

      client.chat(model: model, provider: provider, assume_model_exists: true)
    end
  end
end
