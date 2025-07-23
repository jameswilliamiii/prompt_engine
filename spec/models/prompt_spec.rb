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