module PromptEngine
  class Setting < ApplicationRecord
    self.table_name = "prompt_engine_settings"

    # Rails automatically encrypts these attributes
    encrypts :openai_api_key
    encrypts :anthropic_api_key

    # Singleton pattern - only one settings record should exist
    def self.instance
      first_or_create!
    end

    # Check if API keys are configured
    def openai_configured?
      openai_api_key.present?
    end

    def anthropic_configured?
      anthropic_api_key.present?
    end

    # Get masked API key for display (show only first and last 3 characters)
    def masked_openai_api_key
      mask_api_key(openai_api_key)
    end

    def masked_anthropic_api_key
      mask_api_key(anthropic_api_key)
    end

    private

    def mask_api_key(key)
      return nil if key.blank?
      return "*****" if key.length <= 6

      # Show first 3 characters, then ..., then last 3 characters
      # e.g., "sk-abc123xyz789" becomes "sk-...789"
      first_part = key[0..2]  # First 3 characters
      last_part = key[-3..]   # Last 3 characters
      "#{first_part}...#{last_part}"
    end
  end
end
