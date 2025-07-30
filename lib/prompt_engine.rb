require "prompt_engine/version"
require "prompt_engine/engine"
require "prompt_engine/rendered_prompt"
require "prompt_engine/errors"

module PromptEngine
  class << self
    # Render a prompt by slug with variables and options
    # @param slug [String] The slug of the prompt to render
    # @param variables [Hash] Variables to interpolate in the prompt (default: {})
    # @param options [Hash] Rendering options (default: {})
    # @option options [String] :status The status to filter by (defaults to 'active')
    # @option options [String] :model Override the prompt's default model
    # @option options [Float] :temperature Override the prompt's default temperature
    # @option options [Integer] :max_tokens Override the prompt's default max_tokens
    # @option options [Integer] :version Render a specific version number
    def render(slug, variables = {}, options = {})
      # Extract status from options if provided
      status = options.delete(:status) || 'active'
      
      # Find the prompt with the appropriate status
      prompt = find(slug, status: status)
      
      # Merge variables into options for the prompt.render call
      render_options = options.merge(variables)
      prompt.render(**render_options)
    end

    # Find a prompt by slug with optional status filter
    # @param slug [String] The slug of the prompt
    # @param status [String] The status to filter by (defaults to 'active')
    def find(slug, status: 'active')
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
