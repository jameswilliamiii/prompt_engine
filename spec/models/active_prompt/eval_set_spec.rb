require 'rails_helper'

RSpec.describe ActivePrompt::EvalSet, type: :model do
  describe 'associations' do
    it 'belongs to prompt' do
      eval_set = build(:eval_set)
      expect(eval_set).to respond_to(:prompt)
      expect(eval_set.class.reflect_on_association(:prompt).macro).to eq(:belongs_to)
    end

    it 'has many test_cases with dependent destroy' do
      eval_set = build(:eval_set)
      expect(eval_set).to respond_to(:test_cases)
      association = eval_set.class.reflect_on_association(:test_cases)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it 'has many eval_runs with dependent destroy' do
      eval_set = build(:eval_set)
      expect(eval_set).to respond_to(:eval_runs)
      association = eval_set.class.reflect_on_association(:eval_runs)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe 'validations' do
    let(:prompt) { create(:prompt) }
    let(:eval_set) { build(:eval_set, prompt: prompt) }

    it 'validates presence of name' do
      eval_set.name = nil
      expect(eval_set).not_to be_valid
      expect(eval_set.errors[:name]).to include("can't be blank")
    end

    it 'validates uniqueness of name scoped to prompt' do
      create(:eval_set, name: 'Basic Tests', prompt: prompt)
      
      duplicate = build(:eval_set, name: 'Basic Tests', prompt: prompt)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
      
      # Same name for different prompt should be valid
      other_prompt = create(:prompt)
      different_prompt_eval = build(:eval_set, name: 'Basic Tests', prompt: other_prompt)
      expect(different_prompt_eval).to be_valid
    end
    
    it 'validates presence of grader_type' do
      eval_set.grader_type = nil
      expect(eval_set).not_to be_valid
      expect(eval_set.errors[:grader_type]).to include("can't be blank")
    end
    
    it 'validates inclusion of grader_type' do
      eval_set.grader_type = 'invalid_type'
      expect(eval_set).not_to be_valid
      expect(eval_set.errors[:grader_type]).to include("is not included in the list")
    end
    
    it 'accepts valid grader types' do
      %w[exact_match regex contains json_schema].each do |grader_type|
        eval_set.grader_type = grader_type
        # Set appropriate config for grader types that require it
        case grader_type
        when 'regex'
          eval_set.grader_config = { 'pattern' => '^test$' }
        when 'json_schema'
          eval_set.grader_config = { 'schema' => { 'type' => 'object' } }
        end
        expect(eval_set).to be_valid
      end
    end
    
    describe 'grader_config validation' do
      context 'when grader_type is regex' do
        before { eval_set.grader_type = 'regex' }
        
        it 'requires pattern in grader_config' do
          eval_set.grader_config = {}
          expect(eval_set).not_to be_valid
          expect(eval_set.errors[:grader_config]).to include("regex pattern is required")
        end
        
        it 'validates regex pattern syntax' do
          eval_set.grader_config = { 'pattern' => '[invalid' }
          expect(eval_set).not_to be_valid
          expect(eval_set.errors[:grader_config]).to include(/invalid regex pattern/)
        end
        
        it 'accepts valid regex pattern' do
          eval_set.grader_config = { 'pattern' => '^Hello.*world$' }
          expect(eval_set).to be_valid
        end
      end
      
      context 'when grader_type is json_schema' do
        before { eval_set.grader_type = 'json_schema' }
        
        it 'requires schema in grader_config' do
          eval_set.grader_config = {}
          expect(eval_set).not_to be_valid
          expect(eval_set.errors[:grader_config]).to include("JSON schema is required")
        end
        
        it 'requires type field in schema' do
          eval_set.grader_config = { 'schema' => { 'properties' => {} } }
          expect(eval_set).not_to be_valid
          expect(eval_set.errors[:grader_config]).to include("JSON schema must include a 'type' field")
        end
        
        it 'accepts valid JSON schema' do
          eval_set.grader_config = { 
            'schema' => { 
              'type' => 'object',
              'properties' => { 'name' => { 'type' => 'string' } },
              'required' => ['name']
            }
          }
          expect(eval_set).to be_valid
        end
      end
      
      context 'when grader_type is exact_match or contains' do
        it 'does not require grader_config for exact_match' do
          eval_set.grader_type = 'exact_match'
          eval_set.grader_config = {}
          expect(eval_set).to be_valid
        end
        
        it 'does not require grader_config for contains' do
          eval_set.grader_type = 'contains'
          eval_set.grader_config = {}
          expect(eval_set).to be_valid
        end
      end
    end
  end

  describe 'scopes' do
    let!(:eval_set1) { create(:eval_set, name: 'Alpha') }
    let!(:eval_set2) { create(:eval_set, name: 'Beta') }
    let!(:eval_set3) { create(:eval_set, name: 'Charlie') }

    describe '.by_name' do
      it 'orders eval sets by name' do
        expect(ActivePrompt::EvalSet.by_name).to eq([eval_set1, eval_set2, eval_set3])
      end
    end

    describe '.with_test_cases' do
      it 'includes test cases' do
        create(:test_case, eval_set: eval_set1)
        result = ActivePrompt::EvalSet.with_test_cases.first
        expect(result.association(:test_cases)).to be_loaded
      end
    end
  end

  describe 'instance methods' do
    let(:prompt) { create(:prompt) }
    let(:eval_set) { create(:eval_set, prompt: prompt) }

    describe '#latest_run' do
      it 'returns the most recent eval run' do
        old_run = create(:eval_run, eval_set: eval_set, created_at: 2.days.ago)
        recent_run = create(:eval_run, eval_set: eval_set, created_at: 1.hour.ago)
        
        expect(eval_set.latest_run).to eq(recent_run)
      end

      it 'returns nil when no runs exist' do
        expect(eval_set.latest_run).to be_nil
      end
    end

    describe '#average_success_rate' do
      it 'calculates average success rate across completed runs' do
        version = create(:prompt_version, prompt: prompt)
        create(:eval_run, eval_set: eval_set, prompt_version: version, 
               status: :completed, total_count: 10, passed_count: 8)
        create(:eval_run, eval_set: eval_set, prompt_version: version,
               status: :completed, total_count: 20, passed_count: 15)
        
        # (8 + 15) / (10 + 20) = 23/30 = 76.7%
        expect(eval_set.average_success_rate).to eq(76.7)
      end

      it 'returns 0 when no completed runs exist' do
        create(:eval_run, eval_set: eval_set, status: :pending)
        expect(eval_set.average_success_rate).to eq(0)
      end

      it 'returns 0 when completed runs have no tests' do
        version = create(:prompt_version, prompt: prompt)
        create(:eval_run, eval_set: eval_set, prompt_version: version,
               status: :completed, total_count: 0)
        expect(eval_set.average_success_rate).to eq(0)
      end
    end

    describe '#ready_to_run?' do
      it 'returns true when test cases exist' do
        create(:test_case, eval_set: eval_set)
        expect(eval_set.ready_to_run?).to be true
      end

      it 'returns false when no test cases exist' do
        expect(eval_set.ready_to_run?).to be false
      end
    end

    describe '#openai_eval_id persistence' do
      it 'can store and retrieve openai_eval_id' do
        eval_set.openai_eval_id = 'eval_123abc'
        eval_set.save!
        
        reloaded = ActivePrompt::EvalSet.find(eval_set.id)
        expect(reloaded.openai_eval_id).to eq('eval_123abc')
      end
    end
    
    describe '#grader_type_display' do
      it 'returns human-readable grader type names' do
        eval_set.grader_type = 'exact_match'
        expect(eval_set.grader_type_display).to eq('Exact Match')
        
        eval_set.grader_type = 'regex'
        expect(eval_set.grader_type_display).to eq('Regular Expression')
        
        eval_set.grader_type = 'contains'
        expect(eval_set.grader_type_display).to eq('Contains Text')
        
        eval_set.grader_type = 'json_schema'
        expect(eval_set.grader_type_display).to eq('JSON Schema')
      end
    end
    
    describe '#requires_grader_config?' do
      it 'returns true for regex grader type' do
        eval_set.grader_type = 'regex'
        expect(eval_set.requires_grader_config?).to be true
      end
      
      it 'returns true for json_schema grader type' do
        eval_set.grader_type = 'json_schema'
        expect(eval_set.requires_grader_config?).to be true
      end
      
      it 'returns false for exact_match grader type' do
        eval_set.grader_type = 'exact_match'
        expect(eval_set.requires_grader_config?).to be false
      end
      
      it 'returns false for contains grader type' do
        eval_set.grader_type = 'contains'
        expect(eval_set.requires_grader_config?).to be false
      end
    end
  end
end