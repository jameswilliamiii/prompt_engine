require "prompt_engine/version"
require "prompt_engine/engine"
require "prompt_engine/rendered_prompt"
require "prompt_engine/errors"

module PromptEngine
  class << self
    # Render a prompt by slug with variables and options
    def render(slug, **options)
      prompt = find(slug)
      prompt.render(**options)
    end

    # Find a prompt by slug
    def find(slug)
      Prompt.find_by_slug!(slug)
    end

    # Alias for array-like access
    def [](slug)
      find(slug)
    end
  end
end
