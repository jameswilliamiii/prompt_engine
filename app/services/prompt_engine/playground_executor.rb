module PromptEngine
  class PlaygroundExecutor
    attr_reader :prompt, :model, :provider, :api_key, :parameters

    def initialize(prompt:, model:, api_key:, parameters: {})
      @prompt = prompt
      @model = model
      @api_key = api_key
      @parameters = parameters || {}
      @provider = PromptEngine.config.models.dig(model, :provider)
    end

    def execute
      validate_inputs!

      start_time = Time.current

      parser = ParameterParser.new(prompt.content)
      processed_content = parser.replace_parameters(parameters)

      configure_ruby_llm

      chat = RubyLLM.chat(model: model)

      if prompt.temperature.present?
        chat = chat.with_temperature(prompt.temperature)
      end

      if prompt.system_message.present?
        chat = chat.with_instructions(prompt.system_message)
      end

      response = chat.ask(processed_content)

      execution_time = (Time.current - start_time).round(3)

      response_content = if response.respond_to?(:content)
        response.content
      elsif response.is_a?(String)
        response
      else
        response.to_s
      end

      token_count = if response.respond_to?(:input_tokens) && response.respond_to?(:output_tokens)
        (response.input_tokens || 0) + (response.output_tokens || 0)
      else
        0
      end

      {
        response: response_content,
        execution_time: execution_time,
        token_count: token_count,
        model: model,
        provider: provider
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

    def configure_ruby_llm
      require "ruby_llm"

      RubyLLM.configure do |config|
        case provider
        when "anthropic"
          config.anthropic_api_key = api_key
        when "openai"
          config.openai_api_key = api_key
        end
      end
    end

    def handle_error(error)
      raise error if error.is_a?(ArgumentError)

      case error
      when Net::HTTPUnauthorized
        raise "Invalid API key"
      when Net::HTTPTooManyRequests
        raise "Rate limit exceeded. Please try again later."
      when Net::HTTPError
        raise "Network error. Please check your connection and try again."
      else
        error_message = error.message.to_s
        case error_message
        when /unauthorized/i
          raise "Invalid API key"
        when /rate limit/i
          raise "Rate limit exceeded. Please try again later."
        when /network/i
          raise "Network error. Please check your connection and try again."
        else
          raise "An error occurred: #{error.message}"
        end
      end
    end
  end
end
