require "prompt_engine/version"
require "prompt_engine/engine"

module PromptEngine
  class << self
    # Renders a prompt by name with the given variables
    # @param prompt_name [String, Symbol] The name of the prompt to render
    # @param variables [Hash] Variables to interpolate into the prompt
    # @return [Hash] The rendered prompt with content and system_message
    def render(prompt_name, variables: {})
      prompt = Prompt.active.find_by!(name: prompt_name.to_s)

      {
        content: interpolate_variables(prompt.content, variables),
        system_message: interpolate_variables(prompt.system_message, variables),
        model: prompt.model,
        temperature: prompt.temperature,
        max_tokens: prompt.max_tokens
      }
    end

    private

    def interpolate_variables(text, variables)
      return text if text.blank? || variables.empty?

      text.gsub(/\{\{(\w+)\}\}/) do |match|
        key = $1.to_sym
        variables.fetch(key) { match }
      end
    end
  end
end
