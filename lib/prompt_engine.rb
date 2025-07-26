require "prompt_engine/version"
require "prompt_engine/engine"
require "prompt_engine/rendered_prompt"
require "prompt_engine/errors"
require "prompt_engine/authentication"

module PromptEngine
  # Configuration for authentication
  mattr_accessor :authentication_enabled, default: true
  mattr_accessor :http_basic_auth_enabled, default: false
  mattr_accessor :http_basic_auth_name, default: nil
  mattr_accessor :http_basic_auth_password, default: nil

  class << self
    def configure
      yield self if block_given?
    end
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

    # Check if HTTP Basic Auth should be used
    def use_http_basic_auth?
      http_basic_auth_enabled && http_basic_auth_name.present? && http_basic_auth_password.present?
    end
  end
end
