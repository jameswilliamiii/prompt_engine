require 'rails_helper'

module ActivePrompt
  RSpec.describe "TestCases", type: :request do
    let(:prompt) { create(:prompt, content: "Tell me about {{topic}} in a {{tone}} way") }
    let(:eval_set) { create(:eval_set, prompt: prompt) }
    let(:test_case) { create(:test_case, eval_set: eval_set) }
    
    let(:valid_attributes) do
      {
        input_variables: { 
          "topic" => "machine learning", 
          "tone" => "casual" 
        },
        expected_output: "Machine learning is basically teaching computers to learn from data...",
        description: "Test ML explanation in casual tone"
      }
    end
    
    let(:invalid_attributes) do
      {
        input_variables: {},
        expected_output: '',
        description: 'Invalid test case'
      }
    end
    
    describe 'GET /active_prompt/prompts/:prompt_id/eval_sets/:eval_set_id/test_cases/new' do
      before do
        # Update existing parameters with default values
        prompt.parameters.find_by(name: 'topic')&.update(default_value: 'technology')
        prompt.parameters.find_by(name: 'tone')&.update(default_value: 'formal')
      end
      
      it 'returns a success response' do
        get active_prompt.new_prompt_eval_set_test_case_path(prompt, eval_set)
        expect(response).to be_successful
      end
      
      it 'pre-populates with prompt parameters' do
        get active_prompt.new_prompt_eval_set_test_case_path(prompt, eval_set)
        expect(response.body).to include('technology')
        expect(response.body).to include('formal')
      end
    end
    
    describe 'POST /active_prompt/prompts/:prompt_id/eval_sets/:eval_set_id/test_cases' do
      context 'with valid parameters' do
        it 'creates a new TestCase' do
          expect {
            post active_prompt.prompt_eval_set_test_cases_path(prompt, eval_set), 
                 params: { test_case: valid_attributes }
          }.to change(TestCase, :count).by(1)
        end
        
        it 'associates the test case with the eval set' do
          post active_prompt.prompt_eval_set_test_cases_path(prompt, eval_set), 
               params: { test_case: valid_attributes }
          test_case = TestCase.last
          expect(test_case.eval_set).to eq(eval_set)
        end
        
        it 'redirects to the eval set' do
          post active_prompt.prompt_eval_set_test_cases_path(prompt, eval_set), 
               params: { test_case: valid_attributes }
          expect(response).to redirect_to(active_prompt.prompt_eval_set_path(prompt, eval_set))
        end
      end
      
      context 'with invalid parameters' do
        it 'does not create a new TestCase' do
          expect {
            post active_prompt.prompt_eval_set_test_cases_path(prompt, eval_set), 
                 params: { test_case: invalid_attributes }
          }.not_to change(TestCase, :count)
        end
        
        it 'renders the new template' do
          post active_prompt.prompt_eval_set_test_cases_path(prompt, eval_set), 
               params: { test_case: invalid_attributes }
          expect(response.body).to include('New Test Case')
        end
      end
    end
    
    describe 'GET /active_prompt/prompts/:prompt_id/eval_sets/:eval_set_id/test_cases/:id/edit' do
      it 'returns a success response' do
        get active_prompt.edit_prompt_eval_set_test_case_path(prompt, eval_set, test_case)
        expect(response).to be_successful
      end
      
      it 'displays the test case data' do
        get active_prompt.edit_prompt_eval_set_test_case_path(prompt, eval_set, test_case)
        expect(response.body).to include(test_case.expected_output)
      end
    end
    
    describe 'PATCH /active_prompt/prompts/:prompt_id/eval_sets/:eval_set_id/test_cases/:id' do
      context 'with valid parameters' do
        let(:new_attributes) do
          {
            input_variables: { 
              "topic" => "deep learning", 
              "tone" => "technical" 
            },
            expected_output: "Deep learning is a subset of machine learning...",
            description: "Updated test case"
          }
        end
        
        it 'updates the test case' do
          patch active_prompt.prompt_eval_set_test_case_path(prompt, eval_set, test_case), 
                params: { test_case: new_attributes }
          test_case.reload
          expect(test_case.input_variables["topic"]).to eq("deep learning")
          expect(test_case.expected_output).to include("Deep learning")
          expect(test_case.description).to eq("Updated test case")
        end
        
        it 'redirects to the eval set' do
          patch active_prompt.prompt_eval_set_test_case_path(prompt, eval_set, test_case), 
                params: { test_case: new_attributes }
          expect(response).to redirect_to(active_prompt.prompt_eval_set_path(prompt, eval_set))
        end
      end
      
      context 'with invalid parameters' do
        it 'renders the edit template' do
          patch active_prompt.prompt_eval_set_test_case_path(prompt, eval_set, test_case), 
                params: { test_case: invalid_attributes }
          expect(response.body).to include('Edit Test Case')
        end
      end
    end
    
    describe 'DELETE /active_prompt/prompts/:prompt_id/eval_sets/:eval_set_id/test_cases/:id' do
      let!(:test_case_to_delete) { create(:test_case, eval_set: eval_set) }
      
      it 'destroys the test case' do
        expect {
          delete active_prompt.prompt_eval_set_test_case_path(prompt, eval_set, test_case_to_delete)
        }.to change(TestCase, :count).by(-1)
      end
      
      it 'redirects to the eval set' do
        delete active_prompt.prompt_eval_set_test_case_path(prompt, eval_set, test_case_to_delete)
        expect(response).to redirect_to(active_prompt.prompt_eval_set_path(prompt, eval_set))
      end
      
      it 'does not affect other test cases' do
        other_test_case = create(:test_case, eval_set: eval_set)
        delete active_prompt.prompt_eval_set_test_case_path(prompt, eval_set, test_case_to_delete)
        expect(TestCase.exists?(other_test_case.id)).to be true
      end
    end
  end
end