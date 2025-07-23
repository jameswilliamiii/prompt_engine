require 'rails_helper'

RSpec.describe ActivePrompt::Prompt, type: :model do
  describe 'validations' do
    it 'validates presence of name' do
      prompt = ActivePrompt::Prompt.new(name: nil)
      expect(prompt).not_to be_valid
      expect(prompt.errors[:name]).to include("can't be blank")
    end

    it 'validates uniqueness of name scoped to status' do
      # Create first prompt with required content
      ActivePrompt::Prompt.create!(name: 'test', content: 'Test content', status: 'active')
      
      # Same name with same status should be invalid
      duplicate = ActivePrompt::Prompt.new(name: 'test', content: 'Test content', status: 'active')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
      
      # Same name with different status should be valid
      different_status = ActivePrompt::Prompt.new(name: 'test', content: 'Test content', status: 'draft')
      expect(different_status).to be_valid
    end

    it 'validates inclusion of status' do
      # Rails enum raises ArgumentError for invalid values, so we need to test differently
      prompt = ActivePrompt::Prompt.new(name: 'test', content: 'Test content')
      
      # Test that enum only accepts valid values
      expect { prompt.status = 'invalid' }.to raise_error(ArgumentError)
      
      # Test that valid statuses work
      %w[draft active archived].each do |valid_status|
        prompt.status = valid_status
        prompt.valid?
        expect(prompt.errors[:status]).to be_empty
      end
    end
  end

  describe 'default values' do
    it 'sets status to draft by default' do
      prompt = ActivePrompt::Prompt.new
      expect(prompt.status).to eq('draft')
    end
  end

  describe 'associations' do
    it 'has many versions' do
      prompt = ActivePrompt::Prompt.new
      association = prompt.class.reflect_on_association(:versions)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:class_name]).to eq('ActivePrompt::PromptVersion')
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe 'version control' do
    let(:prompt) { create(:prompt) }

    describe 'creating versions on save' do
      it 'creates initial version on create' do
        new_prompt = nil
        expect {
          new_prompt = ActivePrompt::Prompt.create!(
            name: 'Test Prompt',
            content: 'Initial content',
            system_message: 'Initial system message',
            model: 'gpt-4',
            temperature: 0.7,
            max_tokens: 1000
          )
        }.to change { ActivePrompt::PromptVersion.count }.by(1)
        
        version = new_prompt.versions.first
        expect(version.version_number).to eq(1)
        expect(version.content).to eq('Initial content')
        expect(version.system_message).to eq('Initial system message')
        expect(version.change_description).to eq('Initial version')
      end

      it 'creates new version on update when content changes' do
        prompt.update!(content: 'Updated content')
        
        expect(prompt.versions.count).to eq(2)
        latest_version = prompt.versions.latest.first
        expect(latest_version.version_number).to eq(2)
        expect(latest_version.content).to eq('Updated content')
      end

      it 'creates new version when system_message changes' do
        prompt.update!(system_message: 'Updated system message')
        
        expect(prompt.versions.count).to eq(2)
        latest_version = prompt.versions.latest.first
        expect(latest_version.system_message).to eq('Updated system message')
      end

      it 'creates new version when model changes' do
        prompt.update!(model: 'gpt-3.5-turbo')
        
        expect(prompt.versions.count).to eq(2)
        latest_version = prompt.versions.latest.first
        expect(latest_version.model).to eq('gpt-3.5-turbo')
      end

      it 'creates new version when temperature changes' do
        prompt.update!(temperature: 0.9)
        
        expect(prompt.versions.count).to eq(2)
        latest_version = prompt.versions.latest.first
        expect(latest_version.temperature).to eq(0.9)
      end

      it 'creates new version when max_tokens changes' do
        prompt.update!(max_tokens: 2000)
        
        expect(prompt.versions.count).to eq(2)
        latest_version = prompt.versions.latest.first
        expect(latest_version.max_tokens).to eq(2000)
      end

      it 'does not create version when only non-versioned fields change' do
        prompt.update!(name: 'New Name', description: 'New Description')
        
        expect(prompt.versions.count).to eq(1)
      end

      it 'does not create version when no changes are made' do
        prompt.save!
        
        expect(prompt.versions.count).to eq(1)
      end
    end

    describe '#current_version' do
      it 'returns the latest version' do
        prompt.update!(content: 'Version 2')
        prompt.update!(content: 'Version 3')
        
        current = prompt.current_version
        expect(current.version_number).to eq(3)
        expect(current.content).to eq('Version 3')
      end
    end

    describe '#version_count' do
      it 'returns the number of versions' do
        expect(prompt.version_count).to eq(1)
        
        prompt.update!(content: 'Version 2')
        expect(prompt.version_count).to eq(2)
        
        prompt.update!(content: 'Version 3')
        expect(prompt.version_count).to eq(3)
      end

      it 'uses counter cache when available' do
        # This test assumes we'll add a counter cache column
        # For now, it just tests the method exists
        expect(prompt).to respond_to(:version_count)
      end
    end

    describe '#restore_version!' do
      let!(:version1) { prompt.versions.first }
      let!(:version2) { prompt.update!(content: 'Version 2 content'); prompt.current_version }
      let!(:version3) { prompt.update!(content: 'Version 3 content'); prompt.current_version }

      it 'restores prompt to a specific version' do
        prompt.restore_version!(version1.version_number)
        
        expect(prompt.content).to eq(version1.content)
        expect(prompt.system_message).to eq(version1.system_message)
        expect(prompt.versions.count).to eq(4) # Original 3 + 1 restoration
      end

      it 'raises error for non-existent version' do
        expect {
          prompt.restore_version!(999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe '#version_at' do
      let!(:version1) { prompt.versions.first }
      let!(:version2) { prompt.update!(content: 'Version 2'); prompt.current_version }

      it 'returns the version with specified number' do
        version = prompt.version_at(1)
        expect(version).to eq(version1)
        
        version = prompt.version_at(2)
        expect(version).to eq(version2)
      end

      it 'returns nil for non-existent version' do
        expect(prompt.version_at(999)).to be_nil
      end
    end

    describe '#versioned_attributes_changed?' do
      it 'returns true when versioned attributes change' do
        prompt.content = 'New content'
        expect(prompt.versioned_attributes_changed?).to be true
      end

      it 'returns false when only non-versioned attributes change' do
        prompt.name = 'New name'
        expect(prompt.versioned_attributes_changed?).to be false
      end

      it 'returns false when no attributes change' do
        expect(prompt.versioned_attributes_changed?).to be false
      end
    end
  end
  
  describe 'usage in Rails models' do
    # Create a test model that uses prompts
    before do
      class TestModel
        def self.generate_content(prompt_name, variables = {})
          ActivePrompt.render(prompt_name, variables: variables)
        end
      end
    end
    
    after do
      Object.send(:remove_const, :TestModel) if defined?(TestModel)
    end
    
    context 'when using ActivePrompt.render' do
      let!(:welcome_prompt) do
        ActivePrompt::Prompt.create!(
          name: "welcome_message",
          content: "Welcome {{user_name}}! Thanks for joining {{company_name}}.",
          system_message: "You are a friendly assistant.",
          model: "gpt-4",
          temperature: 0.7,
          max_tokens: 100,
          status: "active"
        )
      end
      
      it 'renders a prompt with variables from a Rails model' do
        result = TestModel.generate_content(:welcome_message, {
          user_name: "Alice",
          company_name: "Acme Corp"
        })
        
        expect(result[:content]).to eq("Welcome Alice! Thanks for joining Acme Corp.")
        expect(result[:system_message]).to eq("You are a friendly assistant.")
        expect(result[:model]).to eq("gpt-4")
        expect(result[:temperature]).to eq(0.7)
        expect(result[:max_tokens]).to eq(100)
      end
      
      it 'only uses active prompts' do
        # Create an archived version
        ActivePrompt::Prompt.create!(
          name: "welcome_message",
          content: "Old content",
          status: "archived"
        )
        
        result = TestModel.generate_content(:welcome_message)
        expect(result[:content]).not_to include("Old content")
      end
      
      it 'raises error for non-existent prompts' do
        expect {
          TestModel.generate_content(:non_existent)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end