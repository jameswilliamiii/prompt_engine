require 'rails_helper'

RSpec.describe PromptEngine::TestCase, type: :model do
  describe 'associations' do
    it 'belongs to eval_set' do
      test_case = build(:test_case)
      expect(test_case).to respond_to(:eval_set)
      expect(test_case.class.reflect_on_association(:eval_set).macro).to eq(:belongs_to)
    end

    it 'has many eval_results with dependent destroy' do
      test_case = build(:test_case)
      expect(test_case).to respond_to(:eval_results)
      association = test_case.class.reflect_on_association(:eval_results)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe 'validations' do
    let(:eval_set) { create(:eval_set) }
    let(:test_case) { build(:test_case, eval_set: eval_set) }

    it 'validates presence of input_variables' do
      test_case.input_variables = nil
      expect(test_case).not_to be_valid
      expect(test_case.errors[:input_variables]).to include("can't be blank")
    end

    it 'validates presence of expected_output' do
      test_case.expected_output = nil
      expect(test_case).not_to be_valid
      expect(test_case.errors[:expected_output]).to include("can't be blank")
    end

    it 'does not allow empty hash for input_variables' do
      test_case.input_variables = {}
      test_case.expected_output = "Hello"
      expect(test_case).not_to be_valid
      expect(test_case.errors[:input_variables]).to include("can't be blank")
    end

    it 'allows description to be optional' do
      test_case.description = nil
      expect(test_case).to be_valid
    end
  end

  describe 'scopes' do
    let(:eval_set) { create(:eval_set) }
    let!(:test_case1) { create(:test_case, eval_set: eval_set, description: 'Beta test') }
    let!(:test_case2) { create(:test_case, eval_set: eval_set, description: 'Alpha test') }
    let!(:test_case3) { create(:test_case, eval_set: eval_set, description: nil) }

    describe '.by_description' do
      it 'orders test cases by description' do
        ordered = eval_set.test_cases.by_description
        expect(ordered.first).to eq(test_case3) # nil comes first
        expect(ordered.second).to eq(test_case2)
        expect(ordered.third).to eq(test_case1)
      end
    end
  end

  describe 'instance methods' do
    let(:eval_set) { create(:eval_set) }
    let(:test_case) { create(:test_case, eval_set: eval_set) }

    describe '#display_name' do
      it 'returns description when present' do
        test_case.description = 'Test user greeting'
        expect(test_case.display_name).to eq('Test user greeting')
      end

      it 'returns default name when description is blank' do
        test_case.description = ''
        test_case.save!
        expect(test_case.display_name).to eq("Test case ##{test_case.id}")
      end

      it 'returns default name when description is nil' do
        test_case.description = nil
        test_case.save!
        expect(test_case.display_name).to eq("Test case ##{test_case.id}")
      end
    end

    describe '#passed_count' do
      it 'counts passed eval results' do
        version = create(:prompt_version, prompt: eval_set.prompt)
        eval_run = create(:eval_run, eval_set: eval_set, prompt_version: version)
        
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: true)
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: true)
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: false)
        
        expect(test_case.passed_count).to eq(2)
      end

      it 'returns 0 when no results exist' do
        expect(test_case.passed_count).to eq(0)
      end
    end

    describe '#failed_count' do
      it 'counts failed eval results' do
        version = create(:prompt_version, prompt: eval_set.prompt)
        eval_run = create(:eval_run, eval_set: eval_set, prompt_version: version)
        
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: false)
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: false)
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: true)
        
        expect(test_case.failed_count).to eq(2)
      end

      it 'returns 0 when no results exist' do
        expect(test_case.failed_count).to eq(0)
      end
    end

    describe '#success_rate' do
      it 'calculates success rate percentage' do
        version = create(:prompt_version, prompt: eval_set.prompt)
        eval_run = create(:eval_run, eval_set: eval_set, prompt_version: version)
        
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: true)
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: true)
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: true)
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: false)
        
        # 3/4 = 75%
        expect(test_case.success_rate).to eq(75.0)
      end

      it 'returns 0 when no results exist' do
        expect(test_case.success_rate).to eq(0)
      end

      it 'returns 0 when all results failed' do
        version = create(:prompt_version, prompt: eval_set.prompt)
        eval_run = create(:eval_run, eval_set: eval_set, prompt_version: version)
        
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: false)
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: false)
        
        expect(test_case.success_rate).to eq(0)
      end

      it 'returns 100 when all results passed' do
        version = create(:prompt_version, prompt: eval_set.prompt)
        eval_run = create(:eval_run, eval_set: eval_set, prompt_version: version)
        
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: true)
        create(:eval_result, test_case: test_case, eval_run: eval_run, passed: true)
        
        expect(test_case.success_rate).to eq(100.0)
      end
    end
  end

  describe 'JSON storage' do
    let(:eval_set) { create(:eval_set) }
    
    it 'stores and retrieves complex input variables' do
      variables = {
        'user_name' => 'John Doe',
        'age' => 30,
        'tags' => ['ruby', 'rails'],
        'metadata' => { 'source' => 'test' }
      }
      
      test_case = create(:test_case, 
        eval_set: eval_set,
        input_variables: variables,
        expected_output: 'Hello John'
      )
      
      reloaded = PromptEngine::TestCase.find(test_case.id)
      expect(reloaded.input_variables).to eq(variables)
      expect(reloaded.input_variables['tags']).to eq(['ruby', 'rails'])
      expect(reloaded.input_variables['metadata']['source']).to eq('test')
    end
  end
end