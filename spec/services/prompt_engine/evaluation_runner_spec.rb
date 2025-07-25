require 'rails_helper'

RSpec.describe PromptEngine::EvaluationRunner, type: :service do
  let(:prompt) { create(:prompt) }
  let(:prompt_version) { create(:prompt_version, prompt: prompt, content: prompt_content) }
  let(:prompt_content) { "Please help with {{topic}} in a {{tone}} tone." }
  let(:eval_set) { create(:eval_set, prompt: prompt, grader_type: grader_type, grader_config: grader_config) }
  let(:eval_run) { create(:eval_run, eval_set: eval_set, prompt_version: prompt_version) }
  let(:runner) { described_class.new(eval_run) }
  let(:grader_type) { 'exact_match' }
  let(:grader_config) { {} }
  let(:mock_client) { instance_double(PromptEngine::OpenAiEvalsClient) }
  
  before do
    allow(PromptEngine::OpenAiEvalsClient).to receive(:new).and_return(mock_client)
  end
  
  describe '#build_testing_criteria' do
    subject(:criteria) { runner.send(:build_testing_criteria) }
    
    context 'with exact_match grader' do
      let(:grader_type) { 'exact_match' }
      
      it 'returns exact match criteria' do
        expect(criteria).to eq([{
          type: "string_check",
          name: "Exact match",
          input: "{{ sample.output_text }}",
          operation: "eq",
          reference: "{{ item.expected_output }}"
        }])
      end
    end
    
    context 'with regex grader' do
      let(:grader_type) { 'regex' }
      let(:grader_config) { { 'pattern' => '^Hello.*world$' } }
      
      it 'returns regex match criteria with pattern from config' do
        expect(criteria).to eq([{
          type: "string_check",
          name: "Regex match",
          input: "{{ sample.output_text }}",
          operation: "regex",
          reference: "^Hello.*world$"
        }])
      end
    end
    
    context 'with contains grader' do
      let(:grader_type) { 'contains' }
      
      it 'returns contains criteria' do
        expect(criteria).to eq([{
          type: "string_check",
          name: "Contains text",
          input: "{{ sample.output_text }}",
          operation: "contains",
          reference: "{{ item.expected_output }}"
        }])
      end
    end
    
    context 'with json_schema grader' do
      let(:grader_type) { 'json_schema' }
      let(:grader_config) do
        {
          'schema' => {
            'type' => 'object',
            'properties' => {
              'name' => { 'type' => 'string' }
            },
            'required' => ['name']
          }
        }
      end
      
      it 'returns JSON schema validation criteria' do
        expect(criteria).to eq([{
          type: "json_schema_check",
          name: "JSON schema validation",
          input: "{{ sample.output_text }}",
          schema: {
            'type' => 'object',
            'properties' => {
              'name' => { 'type' => 'string' }
            },
            'required' => ['name']
          }
        }])
      end
    end
    
    context 'with unknown grader type' do
      # We need to bypass validation to test the default case
      before do
        eval_set.update_column(:grader_type, 'unknown')
      end
      
      it 'defaults to exact match criteria' do
        expect(criteria).to eq([{
          type: "string_check",
          name: "Exact match",
          input: "{{ sample.output_text }}",
          operation: "eq",
          reference: "{{ item.expected_output }}"
        }])
      end
    end
  end
  
  describe '#build_templated_content' do
    subject(:content) { runner.send(:build_templated_content) }
    
    context 'with default content' do
      it 'converts {{variable}} syntax to {{ item.variable }} syntax' do
        expect(content).to eq("Please help with {{ item.topic }} in a {{ item.tone }} tone.")
      end
    end
    
    context 'with multiple variables' do
      let(:prompt_content) { "{{greeting}} {{name}}, how about {{topic}}?" }
      
      it 'handles multiple variables' do
        expect(content).to eq("{{ item.greeting }} {{ item.name }}, how about {{ item.topic }}?")
      end
    end
    
    context 'without variables' do
      let(:prompt_content) { "This is a static prompt." }
      
      it 'preserves content without variables' do
        expect(content).to eq("This is a static prompt.")
      end
    end
  end
end