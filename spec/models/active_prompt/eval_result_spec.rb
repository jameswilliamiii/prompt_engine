require 'rails_helper'

RSpec.describe ActivePrompt::EvalResult, type: :model do
  describe 'associations' do
    it 'belongs to eval_run' do
      eval_result = build(:eval_result)
      expect(eval_result).to respond_to(:eval_run)
      expect(eval_result.class.reflect_on_association(:eval_run).macro).to eq(:belongs_to)
    end

    it 'belongs to test_case' do
      eval_result = build(:eval_result)
      expect(eval_result).to respond_to(:test_case)
      expect(eval_result.class.reflect_on_association(:test_case).macro).to eq(:belongs_to)
    end
  end

  describe 'scopes' do
    let(:prompt) { create(:prompt) }
    let(:version) { create(:prompt_version, prompt: prompt) }
    let(:eval_set) { create(:eval_set, prompt: prompt) }
    let(:eval_run) { create(:eval_run, eval_set: eval_set, prompt_version: version) }
    let(:test_case) { create(:test_case, eval_set: eval_set) }
    
    let!(:passed_result1) { create(:eval_result, eval_run: eval_run, test_case: test_case, passed: true) }
    let!(:passed_result2) { create(:eval_result, eval_run: eval_run, test_case: test_case, passed: true) }
    let!(:failed_result1) { create(:eval_result, eval_run: eval_run, test_case: test_case, passed: false) }
    let!(:failed_result2) { create(:eval_result, eval_run: eval_run, test_case: test_case, passed: false) }

    describe '.passed' do
      it 'returns only passed results' do
        results = ActivePrompt::EvalResult.passed
        expect(results).to include(passed_result1, passed_result2)
        expect(results).not_to include(failed_result1, failed_result2)
      end
    end

    describe '.failed' do
      it 'returns only failed results' do
        results = ActivePrompt::EvalResult.failed
        expect(results).to include(failed_result1, failed_result2)
        expect(results).not_to include(passed_result1, passed_result2)
      end
    end

    describe '.by_execution_time' do
      let!(:fast_result) { create(:eval_result, eval_run: eval_run, test_case: test_case, execution_time_ms: 100) }
      let!(:slow_result) { create(:eval_result, eval_run: eval_run, test_case: test_case, execution_time_ms: 500) }
      let!(:medium_result) { create(:eval_result, eval_run: eval_run, test_case: test_case, execution_time_ms: 300) }

      it 'orders results by execution time ascending' do
        results = [fast_result, slow_result, medium_result]
        ordered = ActivePrompt::EvalResult.where(id: results.map(&:id)).by_execution_time
        expect(ordered.map(&:execution_time_ms)).to eq([100, 300, 500])
      end
    end
  end

  describe 'instance methods' do
    let(:prompt) { create(:prompt) }
    let(:version) { create(:prompt_version, prompt: prompt) }
    let(:eval_set) { create(:eval_set, prompt: prompt) }
    let(:eval_run) { create(:eval_run, eval_set: eval_set, prompt_version: version) }
    let(:test_case) { create(:test_case, eval_set: eval_set) }
    let(:eval_result) { create(:eval_result, eval_run: eval_run, test_case: test_case) }

    describe '#execution_time_seconds' do
      it 'converts milliseconds to seconds' do
        eval_result.execution_time_ms = 1500
        expect(eval_result.execution_time_seconds).to eq(1.5)
      end

      it 'returns nil when execution_time_ms is nil' do
        eval_result.execution_time_ms = nil
        expect(eval_result.execution_time_seconds).to be_nil
      end

      it 'handles fractional seconds' do
        eval_result.execution_time_ms = 250
        expect(eval_result.execution_time_seconds).to eq(0.25)
      end
    end

    describe '#status' do
      it 'returns "passed" when passed is true' do
        eval_result.passed = true
        expect(eval_result.status).to eq("passed")
      end

      it 'returns "failed" when passed is false' do
        eval_result.passed = false
        expect(eval_result.status).to eq("failed")
      end
    end
  end

  describe 'data storage' do
    let(:prompt) { create(:prompt) }
    let(:version) { create(:prompt_version, prompt: prompt) }
    let(:eval_set) { create(:eval_set, prompt: prompt) }
    let(:eval_run) { create(:eval_run, eval_set: eval_set, prompt_version: version) }
    let(:test_case) { create(:test_case, eval_set: eval_set) }

    it 'stores actual output' do
      result = create(:eval_result,
        eval_run: eval_run,
        test_case: test_case,
        actual_output: "Hello, John! Welcome to our service.",
        passed: true
      )
      
      reloaded = ActivePrompt::EvalResult.find(result.id)
      expect(reloaded.actual_output).to eq("Hello, John! Welcome to our service.")
    end

    it 'stores error messages' do
      result = create(:eval_result,
        eval_run: eval_run,
        test_case: test_case,
        passed: false,
        error_message: "API timeout after 30 seconds"
      )
      
      reloaded = ActivePrompt::EvalResult.find(result.id)
      expect(reloaded.error_message).to eq("API timeout after 30 seconds")
    end

    it 'defaults passed to false' do
      result = ActivePrompt::EvalResult.new(
        eval_run: eval_run,
        test_case: test_case
      )
      expect(result.passed).to eq(false)
    end
  end

  describe 'relationships integrity' do
    let(:prompt) { create(:prompt) }
    let(:version) { create(:prompt_version, prompt: prompt) }
    let(:eval_set) { create(:eval_set, prompt: prompt) }
    let(:eval_run) { create(:eval_run, eval_set: eval_set, prompt_version: version) }
    let(:test_case) { create(:test_case, eval_set: eval_set) }
    let(:eval_result) { create(:eval_result, eval_run: eval_run, test_case: test_case) }

    it 'can access prompt through associations' do
      expect(eval_result.eval_run.prompt_version.prompt).to eq(prompt)
      expect(eval_result.test_case.eval_set.prompt).to eq(prompt)
    end

    it 'belongs to the same eval set through different paths' do
      expect(eval_result.eval_run.eval_set).to eq(eval_result.test_case.eval_set)
    end
  end
end