module PromptEngine
  class RenderedPrompt
    attr_reader :prompt, :content, :system_message, :model,
                :temperature, :max_tokens, :variables_used, :overrides,
                :version_number

    def initialize(prompt, rendered_data, overrides = {})
      @prompt = prompt
      @content = rendered_data[:content]
      @system_message = rendered_data[:system_message]
      @variables_used = rendered_data[:parameters_used]
      @overrides = overrides
      @version_number = rendered_data[:version_number]

      # Apply overrides for model settings
      @model = overrides[:model] || rendered_data[:model]
      @temperature = overrides[:temperature] || rendered_data[:temperature]
      @max_tokens = overrides[:max_tokens] || rendered_data[:max_tokens]
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

      # Merge with additional options
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

    # Convenience methods
    def to_h
      {
        content: content,
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        messages: messages,
        overrides: overrides,
        version_number: version_number
      }
    end

    def inspect
      version_info = version_number ? " version=#{version_number}" : ""
      "#<PromptEngine::RenderedPrompt prompt=#{prompt.slug}#{version_info} variables=#{variables_used.keys} overrides=#{overrides.keys}>"
    end
  end
end