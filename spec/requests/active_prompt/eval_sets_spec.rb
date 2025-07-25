require 'rails_helper'

module ActivePrompt
  RSpec.describe "EvalSets", type: :request do
    let(:prompt) { create(:prompt) }
    let(:eval_set) { create(:eval_set, prompt: prompt) }
    
    let(:valid_attributes) do
      {
        name: 'New Eval Set',
        description: 'Testing prompt accuracy',
        grader_type: 'exact_match'
      }
    end
    
    let(:invalid_attributes) do
      {
        name: '',
        description: 'Missing required name',
        grader_type: 'exact_match'
      }
    end
    
    describe 'GET /active_prompt/prompts/:prompt_id/eval_sets' do
      let!(:eval_set1) { create(:eval_set, prompt: prompt, name: 'First Eval') }
      let!(:eval_set2) { create(:eval_set, prompt: prompt, name: 'Second Eval') }
      let!(:other_eval_set) { create(:eval_set) } # Different prompt
      
      it 'returns a success response' do
        get active_prompt.prompt_eval_sets_path(prompt)
        expect(response).to be_successful
      end
      
      it 'displays eval sets for the prompt' do
        get active_prompt.prompt_eval_sets_path(prompt)
        expect(response.body).to include(eval_set1.name)
        expect(response.body).to include(eval_set2.name)
      end
      
      it 'does not display eval sets from other prompts' do
        get active_prompt.prompt_eval_sets_path(prompt)
        expect(response.body).not_to include(other_eval_set.name)
      end
    end
    
    describe 'GET /active_prompt/prompts/:prompt_id/eval_sets/:id' do
      let!(:test_case1) { create(:test_case, eval_set: eval_set) }
      let!(:test_case2) { create(:test_case, eval_set: eval_set) }
      
      it 'returns a success response' do
        get active_prompt.prompt_eval_set_path(prompt, eval_set)
        expect(response).to be_successful
      end
      
      it 'displays the eval set details' do
        get active_prompt.prompt_eval_set_path(prompt, eval_set)
        expect(response.body).to include(eval_set.name)
        expect(response.body).to include(eval_set.description)
      end
      
      it 'displays associated test cases' do
        get active_prompt.prompt_eval_set_path(prompt, eval_set)
        expect(response.body).to include(test_case1.description)
        expect(response.body).to include(test_case2.description)
      end
    end
    
    describe 'GET /active_prompt/prompts/:prompt_id/eval_sets/new' do
      it 'returns a success response' do
        get active_prompt.new_prompt_eval_set_path(prompt)
        expect(response).to be_successful
      end
    end
    
    describe 'POST /active_prompt/prompts/:prompt_id/eval_sets' do
      context 'with valid parameters' do
        it 'creates a new EvalSet' do
          expect {
            post active_prompt.prompt_eval_sets_path(prompt), params: { eval_set: valid_attributes }
          }.to change(EvalSet, :count).by(1)
        end
        
        it 'redirects to the created eval_set' do
          post active_prompt.prompt_eval_sets_path(prompt), params: { eval_set: valid_attributes }
          expect(response).to redirect_to(active_prompt.prompt_eval_set_path(prompt, EvalSet.last))
        end
      end
      
      context 'with invalid parameters' do
        it 'does not create a new EvalSet' do
          expect {
            post active_prompt.prompt_eval_sets_path(prompt), params: { eval_set: invalid_attributes }
          }.not_to change(EvalSet, :count)
        end
        
        it 'renders the new template' do
          post active_prompt.prompt_eval_sets_path(prompt), params: { eval_set: invalid_attributes }
          expect(response.body).to include('New Evaluation Set')
        end
      end
      
      context 'with grader types' do
        context 'when creating regex grader' do
          let(:regex_attributes) do
            {
              name: 'Regex Eval Set',
              description: 'Tests with regex matching',
              grader_type: 'regex',
              grader_config: { 'pattern' => '^Hello.*world$' }
            }
          end
          
          it 'creates eval set with regex configuration' do
            expect {
              post active_prompt.prompt_eval_sets_path(prompt), params: { eval_set: regex_attributes }
            }.to change(EvalSet, :count).by(1)
            
            eval_set = EvalSet.last
            expect(eval_set.grader_type).to eq('regex')
            expect(eval_set.grader_config['pattern']).to eq('^Hello.*world$')
          end
          
          it 'validates regex pattern' do
            regex_attributes[:grader_config] = { 'pattern' => '[invalid' }
            post active_prompt.prompt_eval_sets_path(prompt), params: { eval_set: regex_attributes }
            expect(response.body).to include('invalid regex pattern')
          end
        end
        
        context 'when creating json_schema grader' do
          let(:json_schema_attributes) do
            {
              name: 'JSON Schema Eval Set',
              description: 'Tests with JSON schema validation',
              grader_type: 'json_schema',
              grader_config: { 
                'schema' => { 
                  'type' => 'object',
                  'properties' => { 'name' => { 'type' => 'string' } }
                }
              }
            }
          end
          
          it 'creates eval set with JSON schema configuration' do
            expect {
              post active_prompt.prompt_eval_sets_path(prompt), params: { eval_set: json_schema_attributes }
            }.to change(EvalSet, :count).by(1)
            
            eval_set = EvalSet.last
            expect(eval_set.grader_type).to eq('json_schema')
            expect(eval_set.grader_config['schema']['type']).to eq('object')
          end
        end
      end
    end
    
    describe 'GET /active_prompt/prompts/:prompt_id/eval_sets/:id/edit' do
      it 'returns a success response' do
        get active_prompt.edit_prompt_eval_set_path(prompt, eval_set)
        expect(response).to be_successful
      end
    end
    
    describe 'PATCH /active_prompt/prompts/:prompt_id/eval_sets/:id' do
      context 'with valid parameters' do
        let(:new_attributes) do
          {
            name: 'Updated Eval Set',
            description: 'Updated description',
            grader_type: 'regex',
            grader_config: { 'pattern' => '^test.*' }
          }
        end
        
        it 'updates the eval_set' do
          patch active_prompt.prompt_eval_set_path(prompt, eval_set), params: { eval_set: new_attributes }
          eval_set.reload
          expect(eval_set.name).to eq('Updated Eval Set')
          expect(eval_set.description).to eq('Updated description')
          expect(eval_set.grader_type).to eq('regex')
          expect(eval_set.grader_config['pattern']).to eq('^test.*')
        end
        
        it 'redirects to the eval_set' do
          patch active_prompt.prompt_eval_set_path(prompt, eval_set), params: { eval_set: new_attributes }
          expect(response).to redirect_to(active_prompt.prompt_eval_set_path(prompt, eval_set))
        end
      end
      
      context 'with invalid parameters' do
        it 'renders the edit template' do
          patch active_prompt.prompt_eval_set_path(prompt, eval_set), params: { eval_set: invalid_attributes }
          expect(response.body).to include('Edit Evaluation Set')
        end
      end
    end
    
    describe 'DELETE /active_prompt/prompts/:prompt_id/eval_sets/:id' do
      let!(:eval_set_to_delete) { create(:eval_set, prompt: prompt) }
      
      it 'destroys the eval_set' do
        expect {
          delete active_prompt.prompt_eval_set_path(prompt, eval_set_to_delete)
        }.to change(EvalSet, :count).by(-1)
      end
      
      it 'redirects to the eval_sets list' do
        delete active_prompt.prompt_eval_set_path(prompt, eval_set_to_delete)
        expect(response).to redirect_to(active_prompt.prompt_eval_sets_path(prompt))
      end
    end
    
    describe 'POST /active_prompt/prompts/:prompt_id/eval_sets/:id/run' do
      let(:prompt_version) { create(:prompt_version, prompt: prompt) }
      
      before do
        # Create Settings with API key
        ActivePrompt::Setting.instance.update!(openai_api_key: 'sk-test-key-123')
        
        allow_any_instance_of(Prompt).to receive(:current_version).and_return(prompt_version)
        allow_any_instance_of(ActivePrompt::EvaluationRunner).to receive(:execute).and_return(true)
      end
      
      it 'creates a new eval run' do
        expect {
          post active_prompt.run_prompt_eval_set_path(prompt, eval_set)
        }.to change(EvalRun, :count).by(1)
      end
      
      it 'uses the current prompt version' do
        post active_prompt.run_prompt_eval_set_path(prompt, eval_set)
        eval_run = EvalRun.last
        expect(eval_run.prompt_version).to eq(prompt_version)
      end
      
      it 'calls EvaluationRunner' do
        expect_any_instance_of(ActivePrompt::EvaluationRunner).to receive(:execute)
        post active_prompt.run_prompt_eval_set_path(prompt, eval_set)
      end
      
      it 'redirects to the eval run' do
        post active_prompt.run_prompt_eval_set_path(prompt, eval_set)
        eval_run = EvalRun.last
        expect(response).to redirect_to(active_prompt.prompt_eval_run_path(prompt, eval_run))
      end
      
      context 'when evaluation fails' do
        before do
          allow_any_instance_of(ActivePrompt::EvaluationRunner).to receive(:execute).and_raise(StandardError, "API Error")
        end
        
        it 'still creates the eval run' do
          expect {
            post active_prompt.run_prompt_eval_set_path(prompt, eval_set) rescue nil
          }.to change(EvalRun, :count).by(1)
        end
        
        it 'handles the error gracefully' do
          post active_prompt.run_prompt_eval_set_path(prompt, eval_set)
          
          expect(response).to redirect_to(active_prompt.prompt_eval_set_path(prompt, eval_set))
          expect(flash[:alert]).to include("Evaluation failed: API Error")
          
          # Verify the run was marked as failed
          eval_run = EvalRun.last
          expect(eval_run.status).to eq('failed')
          expect(eval_run.error_message).to eq("API Error")
        end
      end
    end
  end
end