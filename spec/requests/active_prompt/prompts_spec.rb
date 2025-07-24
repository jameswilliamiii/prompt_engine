require 'rails_helper'

module ActivePrompt
  RSpec.describe "Prompts", type: :request do
    let(:valid_attributes) do
      {
        name: 'Test Prompt',
        description: 'A test prompt',
        content: 'Generate a {{type}} response',
        system_message: 'You are a helpful assistant',
        model: 'gpt-4',
        temperature: 0.7,
        max_tokens: 1000,
        status: 'draft'
      }
    end

    let(:invalid_attributes) do
      {
        name: '',
        content: '',
        description: 'Invalid prompt without required fields'
      }
    end

    describe 'GET /active_prompt/prompts' do
      let!(:prompt1) { create(:prompt, name: 'First Prompt') }
      let!(:prompt2) { create(:prompt, name: 'Second Prompt') }

      it 'returns a success response' do
        get active_prompt.prompts_path
        expect(response).to be_successful
      end

      it 'displays all prompts' do
        get active_prompt.prompts_path
        expect(response.body).to include(prompt1.name)
        expect(response.body).to include(prompt2.name)
      end
    end

    describe 'GET /active_prompt/prompts/:id' do
      let(:prompt) { create(:prompt) }

      it 'returns a success response' do
        get active_prompt.prompt_path(prompt)
        expect(response).to be_successful
      end

      it 'displays the prompt details' do
        get active_prompt.prompt_path(prompt)
        expect(response.body).to include(prompt.name)
        expect(response.body).to include(prompt.description)
      end
    end

    describe 'GET /active_prompt/prompts/new' do
      it 'returns a success response' do
        get active_prompt.new_prompt_path
        expect(response).to be_successful
      end

      it 'displays the new prompt form' do
        get active_prompt.new_prompt_path
        expect(response.body).to include('New Prompt')
      end
    end

    describe 'POST /active_prompt/prompts' do
      context 'with valid params' do
        it 'creates a new Prompt' do
          expect {
            post active_prompt.prompts_path, params: { prompt: valid_attributes }
          }.to change(ActivePrompt::Prompt, :count).by(1)
        end

        it 'redirects to the created prompt' do
          post active_prompt.prompts_path, params: { prompt: valid_attributes }
          expect(response).to redirect_to(active_prompt.prompt_path(ActivePrompt::Prompt.last))
        end

        it 'sets a success notice' do
          post active_prompt.prompts_path, params: { prompt: valid_attributes }
          follow_redirect!
          expect(response.body).to include('Prompt was successfully created.')
        end
      end

      context 'with invalid params' do
        it 'does not create a new Prompt' do
          expect {
            post active_prompt.prompts_path, params: { prompt: invalid_attributes }
          }.not_to change(ActivePrompt::Prompt, :count)
        end

        it 'returns unprocessable entity status' do
          post active_prompt.prompts_path, params: { prompt: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'renders the new template with errors' do
          post active_prompt.prompts_path, params: { prompt: invalid_attributes }
          expect(response.body).to include('error')
        end
      end
    end

    describe 'GET /active_prompt/prompts/:id/edit' do
      let(:prompt) { create(:prompt) }

      it 'returns a success response' do
        get active_prompt.edit_prompt_path(prompt)
        expect(response).to be_successful
      end

      it 'displays the edit form' do
        get active_prompt.edit_prompt_path(prompt)
        expect(response.body).to include('Edit Prompt')
        expect(response.body).to include(prompt.name)
      end
    end

    describe 'PATCH /active_prompt/prompts/:id' do
      let(:prompt) { create(:prompt) }

      context 'with valid params' do
        let(:new_attributes) do
          {
            name: 'Updated Prompt Name',
            description: 'Updated description',
            temperature: 0.9
          }
        end

        it 'updates the requested prompt' do
          patch active_prompt.prompt_path(prompt), params: { prompt: new_attributes }
          prompt.reload
          expect(prompt.name).to eq('Updated Prompt Name')
          expect(prompt.description).to eq('Updated description')
          expect(prompt.temperature).to eq(0.9)
        end

        it 'redirects to the prompt' do
          patch active_prompt.prompt_path(prompt), params: { prompt: new_attributes }
          expect(response).to redirect_to(active_prompt.prompt_path(prompt))
        end

        it 'sets a success notice' do
          patch active_prompt.prompt_path(prompt), params: { prompt: new_attributes }
          follow_redirect!
          expect(response.body).to include('Prompt was successfully updated.')
        end
      end

      context 'with invalid params' do
        it 'does not update the prompt' do
          original_name = prompt.name
          patch active_prompt.prompt_path(prompt), params: { prompt: invalid_attributes }
          prompt.reload
          expect(prompt.name).to eq(original_name)
        end

        it 'returns unprocessable entity status' do
          patch active_prompt.prompt_path(prompt), params: { prompt: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'renders the edit template with errors' do
          patch active_prompt.prompt_path(prompt), params: { prompt: invalid_attributes }
          expect(response.body).to include('error')
        end
      end
    end

    describe 'PUT /active_prompt/prompts/:id' do
      let(:prompt) { create(:prompt) }

      context 'with valid params' do
        let(:new_attributes) do
          {
            name: 'Updated Prompt Name',
            description: 'Updated description',
            temperature: 0.9
          }
        end

        it 'updates the requested prompt' do
          put active_prompt.prompt_path(prompt), params: { prompt: new_attributes }
          prompt.reload
          expect(prompt.name).to eq('Updated Prompt Name')
          expect(prompt.description).to eq('Updated description')
          expect(prompt.temperature).to eq(0.9)
        end

        it 'redirects to the prompt' do
          put active_prompt.prompt_path(prompt), params: { prompt: new_attributes }
          expect(response).to redirect_to(active_prompt.prompt_path(prompt))
        end

        it 'sets a success notice' do
          put active_prompt.prompt_path(prompt), params: { prompt: new_attributes }
          follow_redirect!
          expect(response.body).to include('Prompt was successfully updated.')
        end
      end

      context 'with invalid params' do
        it 'does not update the prompt' do
          original_name = prompt.name
          put active_prompt.prompt_path(prompt), params: { prompt: invalid_attributes }
          prompt.reload
          expect(prompt.name).to eq(original_name)
        end

        it 'returns unprocessable entity status' do
          put active_prompt.prompt_path(prompt), params: { prompt: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'renders the edit template with errors' do
          put active_prompt.prompt_path(prompt), params: { prompt: invalid_attributes }
          expect(response.body).to include('error')
        end
      end
    end

    describe 'DELETE /active_prompt/prompts/:id' do
      let!(:prompt) { create(:prompt) }

      it 'destroys the requested prompt' do
        expect {
          delete active_prompt.prompt_path(prompt)
        }.to change(ActivePrompt::Prompt, :count).by(-1)
      end

      it 'redirects to the prompts list' do
        delete active_prompt.prompt_path(prompt)
        expect(response).to redirect_to(active_prompt.prompts_path)
      end

      it 'sets a success notice' do
        delete active_prompt.prompt_path(prompt)
        follow_redirect!
        expect(response.body).to include('Prompt was successfully deleted.')
      end
    end
  end
end
