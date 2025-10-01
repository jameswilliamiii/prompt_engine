require 'rails_helper'

RSpec.describe PromptEngine::ToolsController, type: :request do
  let(:prompt) { create(:prompt) }
  let(:tool_class_name) { 'ExampleTool' }

  before do
    # Ensure the prompt is saved and has an ID
    prompt.save!
  end

  describe 'GET /prompts/:id/tools' do
    it 'returns the tools index page' do
      get prompt_engine.prompt_tools_path(prompt)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /prompts/:id/tools' do
    before do
      allow_any_instance_of(PromptEngine::Prompt).to receive(:add_tool).and_return(true)
      allow_any_instance_of(PromptEngine::Prompt).to receive(:save!).and_return(true)
      allow_any_instance_of(PromptEngine::Prompt).to receive(:tool_info).and_return({
        name: tool_class_name,
        description: 'Test tool'
      })
    end

    it 'adds a tool to the prompt' do
      post prompt_engine.prompt_tools_path(prompt), params: { tool_class_name: tool_class_name }
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
    end
  end

  describe 'DELETE /prompts/:id/tools/:tool_class_name' do
    before do
      allow_any_instance_of(PromptEngine::Prompt).to receive(:remove_tool).and_return(true)
      allow_any_instance_of(PromptEngine::Prompt).to receive(:save!).and_return(true)
    end

    it 'removes a tool from the prompt' do
      delete prompt_engine.prompt_tool_path(prompt, tool_class_name)
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
    end
  end

  describe 'GET /prompts/:id/tools/available' do
    let(:mock_tools) { [double('Tool', name: 'TestTool')] }

    before do
      allow_any_instance_of(PromptEngine::Prompt).to receive(:available_tools).and_return(mock_tools)
      allow(PromptEngine::ToolDiscoveryService).to receive(:tool_info).and_return({
        name: 'TestTool',
        description: 'Test description'
      })
    end

    it 'returns available tools' do
      get prompt_engine.available_prompt_tools_path(prompt)
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['tools']).to be_an(Array)
    end
  end
end
