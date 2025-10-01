require 'rails_helper'

module PromptEngine
  RSpec.describe "Workflows API", type: :request do
    include Engine.routes.url_helpers

    let!(:prompt) { create(:prompt, slug: "test-prompt", status: "enabled") }

    describe "GET /workflows" do
      let!(:workflow) { create(:workflow, name: "test-workflow", steps: { "1" => "test-prompt" }) }

      it "returns all workflows as JSON" do
        get workflows_path
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("application/json; charset=utf-8")

        json_response = JSON.parse(response.body)
        expect(json_response).to be_an(Array)
        expect(json_response.first["name"]).to eq("test-workflow")
      end
    end

    describe "POST /workflows" do
      let(:valid_params) do
        {
          workflow: {
            name: "new-workflow",
            steps: { "1" => "test-prompt" },
            conditions: nil
          }
        }
      end

      let(:invalid_params) do
        {
          workflow: {
            name: "",
            steps: { "1" => "nonexistent-prompt" }
          }
        }
      end

      it "creates a workflow with valid parameters" do
        expect {
          post workflows_path, params: valid_params
        }.to change(Workflow, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["name"]).to eq("new-workflow")
      end

      it "returns errors with invalid parameters" do
        post workflows_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key("errors")
      end
    end

    describe "GET /workflows/:id" do
      let!(:workflow) { create(:workflow, name: "show-workflow", steps: { "1" => "test-prompt" }) }

      it "returns the workflow as JSON" do
        get workflow_path(workflow)
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["name"]).to eq("show-workflow")
      end
    end

    describe "PUT /workflows/:id" do
      let!(:workflow) { create(:workflow, name: "update-workflow", steps: { "1" => "test-prompt" }) }

      it "updates the workflow with valid parameters" do
        put workflow_path(workflow), params: {
          workflow: { name: "updated-workflow" }
        }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["name"]).to eq("updated-workflow")
      end
    end

    describe "DELETE /workflows/:id" do
      let!(:workflow) { create(:workflow, name: "delete-workflow", steps: { "1" => "test-prompt" }) }

      it "deletes the workflow and redirects to index" do
        expect {
          delete workflow_path(workflow)
        }.to change(Workflow, :count).by(-1)

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(workflows_path)
      end

      it "returns JSON format when requested" do
        delete workflow_path(workflow), headers: { 'Accept' => 'application/json' }
        
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
