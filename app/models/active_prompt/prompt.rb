module ActivePrompt
  class Prompt < ApplicationRecord
    self.table_name = "active_prompt_prompts"
    
    has_many :versions, -> { order(version_number: :desc) }, 
             class_name: 'ActivePrompt::PromptVersion',
             dependent: :destroy
    
    attr_accessor :change_summary

    validates :name, presence: true, uniqueness: { scope: :status }
    validates :content, presence: true
    
    enum :status, {
      draft: 'draft',
      active: 'active',
      archived: 'archived'
    }, default: 'draft'
    
    scope :active, -> { where(status: 'active') }
    scope :by_name, -> { order(:name) }

    after_create :create_initial_version
    after_update :create_version_if_changed

    VERSIONED_ATTRIBUTES = %w[content system_message model temperature max_tokens metadata].freeze

    def current_version
      versions.first
    end

    def version_count
      versions_count
    end

    def restore_version!(version_number)
      version = versions.find_by!(version_number: version_number)
      version.restore!
    end

    def version_at(version_number)
      versions.find_by(version_number: version_number)
    end

    def versioned_attributes_changed?
      # This method is for checking if versioned attributes have changed before save
      (changed & VERSIONED_ATTRIBUTES).any?
    end

    private

    def create_initial_version
      versions.create!(
        content: content,
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        metadata: metadata,
        change_description: 'Initial version'
      )
    end

    def create_version_if_changed
      # Check saved_changes in the after_update callback
      return unless (saved_changes.keys & VERSIONED_ATTRIBUTES).any?

      versions.create!(
        content: content,
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        metadata: metadata,
        change_description: "Updated: #{(saved_changes.keys & VERSIONED_ATTRIBUTES).join(', ')}"
      )
    end
  end
end
