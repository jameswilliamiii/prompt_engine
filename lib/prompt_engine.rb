require "prompt_engine/version"
require "prompt_engine/engine"
require "prompt_engine/rendered_prompt"
require "prompt_engine/errors"

module PromptEngine
  class << self
    # Render a prompt by slug with variables and options
    # @param slug [String] The slug of the prompt to render
    # @param variables [Hash] Variables to interpolate in the prompt (default: {})
    # @param options [Hash] Rendering options via keyword argument
    # @option options [String] :status The status to filter by (defaults to 'active')
    # @option options [String] :model Override the prompt's default model
    # @option options [Float] :temperature Override the prompt's default temperature
    # @option options [Integer] :max_tokens Override the prompt's default max_tokens
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

        # Pass along the original status option for the RenderedPrompt
        render_options = options.merge(variables)
      else
        # Extract status from options for finding the prompt
        status = options.delete(:status)

        # Find the prompt with the appropriate status
        prompt = find(slug, status: status)

        # Add status back to options for RenderedPrompt
        render_options = options.merge(variables).merge(status: status)
      end

      prompt.render(**render_options)
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
