module ActivePrompt
  class Prompt < ApplicationRecord
    self.table_name = "active_prompt_prompts"
    
    validates :name, presence: true, uniqueness: { scope: :status }
    validates :content, presence: true
    
    enum :status, {
      draft: 'draft',
      active: 'active',
      archived: 'archived'
    }, default: 'draft'
    
    scope :active, -> { where(status: 'active') }
    scope :by_name, -> { order(:name) }
  end
end
