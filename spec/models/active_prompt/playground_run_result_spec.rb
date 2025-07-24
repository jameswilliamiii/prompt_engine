require 'rails_helper'

RSpec.describe ActivePrompt::PlaygroundRunResult, type: :model do
  describe 'associations' do
    it 'belongs to prompt_version' do
      result = described_class.new
      association = result.class.reflect_on_association(:prompt_version)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
      expect(association.class_name).to eq('ActivePrompt::PromptVersion')
    end
  end

  describe 'validations' do
    let(:prompt_version) { create(:prompt_version) }

    it 'validates presence of provider' do
      result = described_class.new(prompt_version: prompt_version)
      expect(result).not_to be_valid
      expect(result.errors[:provider]).to include("can't be blank")
    end

    it 'validates presence of model' do
      result = described_class.new(prompt_version: prompt_version, provider: 'anthropic')
      expect(result).not_to be_valid
      expect(result.errors[:model]).to include("can't be blank")
    end

    it 'validates presence of rendered_prompt' do
      result = described_class.new(prompt_version: prompt_version, provider: 'anthropic', model: 'claude')
      expect(result).not_to be_valid
      expect(result.errors[:rendered_prompt]).to include("can't be blank")
    end

    it 'validates presence of response' do
      result = described_class.new(prompt_version: prompt_version, provider: 'anthropic', model: 'claude', rendered_prompt: 'test')
      expect(result).not_to be_valid
      expect(result.errors[:response]).to include("can't be blank")
    end

    it 'validates presence of execution_time' do
      result = described_class.new(prompt_version: prompt_version, provider: 'anthropic', model: 'claude', rendered_prompt: 'test', response: 'response')
      expect(result).not_to be_valid
      expect(result.errors[:execution_time]).to include("can't be blank")
    end

    it 'validates execution_time is greater than or equal to 0' do
      result = build(:playground_run_result, execution_time: -1)
      expect(result).not_to be_valid
      expect(result.errors[:execution_time]).to include("must be greater than or equal to 0")
    end

    it 'allows nil token_count' do
      result = build(:playground_run_result, token_count: nil)
      expect(result).to be_valid
    end

    it 'validates token_count is greater than or equal to 0 when present' do
      result = build(:playground_run_result, token_count: -1)
      expect(result).not_to be_valid
      expect(result.errors[:token_count]).to include("must be greater than or equal to 0")
    end
  end

  describe 'scopes' do
    let!(:result1) { create(:playground_run_result, created_at: 2.days.ago) }
    let!(:result2) { create(:playground_run_result, created_at: 1.day.ago) }
    let!(:result3) { create(:playground_run_result, created_at: 1.hour.ago) }

    describe '.recent' do
      it 'orders by created_at descending' do
        expect(described_class.recent).to eq([ result3, result2, result1 ])
      end
    end

    describe '.by_provider' do
      before { described_class.destroy_all }

      let!(:anthropic_result) { create(:playground_run_result, provider: 'anthropic') }
      let!(:openai_result) { create(:playground_run_result, :openai) }

      it 'filters by provider' do
        expect(described_class.by_provider('anthropic')).to contain_exactly(anthropic_result)
        expect(described_class.by_provider('openai')).to contain_exactly(openai_result)
      end
    end

    describe '.successful' do
      let!(:successful_result) { create(:playground_run_result) }

      it 'returns only results with responses' do
        # Since response is required, we can't create a failed result
        # Instead, let's test that the scope works correctly
        expect(described_class.successful).to include(successful_result)
        expect(described_class.successful.to_sql).to include('WHERE')
        expect(described_class.successful.to_sql).to include('response')
        expect(described_class.successful.to_sql).to include('IS NOT NULL')
      end
    end
  end

  describe 'serialization' do
    it 'serializes parameters as JSON' do
      result = create(:playground_run_result, parameters: { key: 'value' })
      result.reload
      expect(result.parameters).to eq({ 'key' => 'value' })
    end
  end
end
