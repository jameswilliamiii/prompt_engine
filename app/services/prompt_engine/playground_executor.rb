module PromptEngine
  class PlaygroundExecutor
    class IncompleteResponseError < StandardError; end

    attr_reader :prompt, :model, :provider, :api_key, :parameters

    def initialize(prompt:, model:, api_key:, parameters: {})
      @prompt = prompt
      @model = model
      @api_key = api_key
      @parameters = parameters || {}
      @provider = PromptEngine.config.provider_for(model)
    end

    def execute
      require "ruby_llm"
      validate_inputs!

      start_time = Time.current

      rendered = RenderedPrompt.new(prompt, {
        content: ParameterParser.new(prompt.content).replace_parameters(parameters),
        system_message: prompt.system_message,
        model: model,
        temperature: prompt.temperature,
        max_tokens: prompt.max_tokens,
        effort: prompt.effort
      })

      response = rendered.execute_with(context)
      ensure_complete!(response)

      {
        response: response.content,
        execution_time: (Time.current - start_time).round(3),
        token_count: response.input_tokens.to_i + response.output_tokens.to_i,
        model: model,
        provider: provider,
        temperature: rendered.temperature,
        max_tokens: rendered.max_tokens,
        effort: rendered.effort
      }
    rescue => e
      handle_error(e)
    end

    private

    def validate_inputs!
      raise ArgumentError, "Model is required" if model.blank?
      raise ArgumentError, "API key is required" if api_key.blank?
      raise ArgumentError, "Unknown model: #{model}" if provider.nil?
    end

    # A context rather than RubyLLM.configure, which would replace the host app's global keys.
    def context
      RubyLLM.context do |config|
        case provider
        when "anthropic"
          config.anthropic_api_key = api_key
        when "openai"
          config.openai_api_key = api_key
        end
      end
    end

    # ruby_llm keeps only the text blocks, so a refusal or a cutoff arrives as an ordinary message.
    def ensure_complete!(response)
      body = response.raw&.body
      return unless body.is_a?(Hash)

      case body["stop_reason"] || body.dig("choices", 0, "finish_reason")
      when "refusal", "content_filter"
        raise IncompleteResponseError, "The model declined to answer this prompt."
      when "max_tokens", "length"
        raise IncompleteResponseError, "The response reached Max Tokens before it finished. Raise Max Tokens and try again."
      end
    end

    def handle_error(error)
      case error
      when ArgumentError, IncompleteResponseError
        raise error
      when RubyLLM::UnauthorizedError
        raise "Invalid API key"
      when RubyLLM::RateLimitError
        raise "Rate limit exceeded. Please try again later."
      when RubyLLM::OverloadedError, RubyLLM::ServiceUnavailableError
        raise "The provider is overloaded. Please try again later."
      when Faraday::ConnectionFailed, Faraday::TimeoutError
        raise "Network error. Please check your connection and try again."
      else
        raise "An error occurred: #{error.message}"
      end
    end
  end
end
