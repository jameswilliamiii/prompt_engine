require "prompt_engine/version"
require "prompt_engine/engine"
require "prompt_engine/rendered_prompt"
require "prompt_engine/errors"

module PromptEngine
  class Configuration
    # Settings for models matched by name, so a newly released model works without a config change.
    # The first matching pattern wins; an entry in #models overrides it key by key.
    DEFAULT_MODEL_FAMILIES = [
      [ /\Aclaude-(fable|mythos)-/, { provider: "anthropic", supports_temperature: false, supports_effort: true } ],
      [ /\Aclaude-(opus|sonnet|haiku)-([5-9]|[1-9]\d)\b/, { provider: "anthropic", supports_temperature: false, supports_effort: true } ],
      [ /\Aclaude-opus-4-[78]\b/, { provider: "anthropic", supports_temperature: false, supports_effort: true } ],
      [ /\Aclaude-(opus|sonnet)-4-6\b/, { provider: "anthropic", supports_effort: true } ],
      [ /\Aclaude-/, { provider: "anthropic" } ],
      [ /\A(gpt-([5-9]|[1-9]\d)|o\d)/, { provider: "openai", supports_temperature: false } ],
      [ /\Agpt-/, { provider: "openai" } ]
    ].freeze

    # Model identifier => { label: "Display Name" }, optionally with provider, supports_temperature
    # and supports_effort to override the family settings. May be a callable returning that hash.
    attr_writer :models
    attr_accessor :model_families
    attr_accessor :back_path
    attr_accessor :back_label

    def initialize
      @back_path = nil
      @back_label = "← Back"
      @model_families = DEFAULT_MODEL_FAMILIES.dup
      @models = {
        "gpt-4.1"           => { label: "GPT-4.1" },
        "gpt-4.1-mini"      => { label: "GPT-4.1 Mini" },
        "gpt-4o"            => { label: "GPT-4o" },
        "claude-opus-5-5"   => { label: "Claude Opus 5.5" },
        "claude-sonnet-5-5" => { label: "Claude Sonnet 5.5" },
        "claude-haiku-5-5"  => { label: "Claude Haiku 5.5" }
      }
    end

    def models
      @models.respond_to?(:call) ? @models.call : @models
    end

    # Pass entry when you already hold it, to skip another call to a callable #models.
    def model_settings(model_id, entry = models[model_id])
      return {} if model_id.blank?

      family = model_families.find { |pattern, _| pattern.match?(model_id) }&.last || {}
      family.merge(entry || {})
    end

    def provider_for(model_id)
      model_settings(model_id)[:provider]
    end

    def supports_temperature?(model_id)
      model_settings(model_id)[:supports_temperature] != false
    end

    def supports_effort?(model_id)
      model_settings(model_id)[:supports_effort] == true
    end
  end

  class << self
    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end

    # Render a prompt by slug with variables and options
    # @param slug [String] The slug of the prompt to render
    # @param variables [Hash] Variables to interpolate in the prompt (default: {})
    # @param options [Hash] Rendering options via keyword argument
    # @option options [String] :status The status to filter by (defaults to 'active')
    # @option options [String] :model Override the prompt's default model
    # @option options [Float] :temperature Override the prompt's default temperature
    # @option options [Integer] :max_tokens Override the prompt's default max_tokens
    # @option options [String] :effort Override the prompt's default effort
    # @option options [Integer] :version Render a specific version number
    def render(slug, variables = {}, options: {})
      # Set defaults for options
      options = {
        status: "active"
      }.merge(options)

      # If version is specified, we need to find the prompt without status filter
      # because we want to load any version regardless of the prompt's current status
      if options[:version]
        # Find prompt by slug only (no status filter)
        prompt = Prompt.find_by_slug!(slug)
      else
        # Extract status from options for finding the prompt
        status = options.delete(:status)

        # Find the prompt with the appropriate status
        prompt = find(slug, status: status)
      end

      prompt.render(variables: variables, **options)
    end

    # Find a prompt by slug with optional status filter
    # @param slug [String] The slug of the prompt
    # @param status [String] The status to filter by (defaults to 'active')
    def find(slug, status: "active")
      if status
        Prompt.where(slug: slug, status: status).first!
      else
        # If explicitly passed as nil, find any status
        Prompt.find_by_slug!(slug)
      end
    end

    # Alias for array-like access (defaults to active status)
    def [](slug)
      find(slug)
    end
  end
end
