# This migration comes from active_prompt (originally 20250724165118)
class CreateActivePromptSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :active_prompt_settings do |t|
      # Encrypted API keys
      t.text :openai_api_key
      t.text :anthropic_api_key

      # Other settings can be added here in the future
      t.json :preferences, default: {}

      t.timestamps
    end
  end
end
