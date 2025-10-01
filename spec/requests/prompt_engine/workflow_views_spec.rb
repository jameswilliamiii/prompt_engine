require 'rails_helper'

module PromptEngine
  RSpec.describe "Workflow Views", type: :request do
    include Engine.routes.url_helpers

    let!(:prompt) { create(:prompt, slug: "test-prompt", status: "enabled") }

    describe "GET /workflows" do
      it "renders the workflows index page" do
        get workflows_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Workflows")
        expect(response.body).to include("New Workflow")
      end

      it "shows empty state when no workflows exist" do
        get workflows_path
        expect(response.body).to include("No workflows yet")
        expect(response.body).to include("Create your first workflow")
      end

      it "lists existing workflows" do
        workflow = create(:workflow, name: "Test Workflow", steps: { "1" => "test-prompt" })
        get workflows_path
        expect(response.body).to include("Test Workflow")
      end
    end

    describe "GET /workflows/new" do
      it "renders the new workflow page" do
        get new_workflow_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("New Workflow")
        expect(response.body).to include("Create Workflow")
      end

      it "shows available prompts in the form" do
        get new_workflow_path
        expect(response.body).to include(prompt.name)
        expect(response.body).to include(prompt.slug)
      end
    end

    describe "GET /workflows/:id" do
      let!(:workflow) { create(:workflow, name: "Test Workflow", steps: { "1" => "test-prompt" }) }

      it "renders the workflow show page" do
        get workflow_path(workflow)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Test Workflow")
        expect(response.body).to include("Workflow Steps")
      end

      it "shows workflow steps with prompt information" do
        get workflow_path(workflow)
        expect(response.body).to include(prompt.name)
        expect(response.body).to include(prompt.slug)
      end

      it "shows usage examples" do
        get workflow_path(workflow)
        expect(response.body).to include("Usage Example")
        expect(response.body).to include("PromptEngine.workflow")
      end
    end

    describe "GET /workflows/:id/edit" do
      let!(:workflow) { create(:workflow, name: "Test Workflow", steps: { "1" => "test-prompt" }) }

      it "renders the edit workflow page" do
        get edit_workflow_path(workflow)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit Workflow")
        expect(response.body).to include(workflow.name)
      end

      it "pre-fills the form with existing workflow data" do
        get edit_workflow_path(workflow)
        expect(response.body).to include('value="Test Workflow"')
        expect(response.body).to include('selected')
      end
    end

    describe "POST /workflows" do
      it "creates a new workflow via HTML form" do
        expect {
          post workflows_path, params: {
            workflow: {
              name: "New Workflow",
              steps: { "1" => "test-prompt" }
            }
          }
        }.to change(Workflow, :count).by(1)

        expect(response).to redirect_to(workflow_path(Workflow.last))
        follow_redirect!
        expect(response.body).to include("Workflow was successfully created")
      end

      it "renders new template with errors for invalid data" do
        post workflows_path, params: {
          workflow: {
            name: "",
            steps: {}
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Please fix the following errors")
      end
    end

    describe "PUT /workflows/:id" do
      let!(:workflow) { create(:workflow, name: "Original Name", steps: { "1" => "test-prompt" }) }

      it "updates the workflow via HTML form" do
        put workflow_path(workflow), params: {
          workflow: {
            name: "Updated Name"
          }
        }

        expect(response).to redirect_to(workflow_path(workflow))
        follow_redirect!
        expect(response.body).to include("Workflow was successfully updated")
        expect(response.body).to include("Updated Name")
      end
    end

    describe "DELETE /workflows/:id" do
      let!(:workflow) { create(:workflow, name: "To Delete", steps: { "1" => "test-prompt" }) }

      it "deletes the workflow and redirects to index" do
        expect {
          delete workflow_path(workflow)
        }.to change(Workflow, :count).by(-1)

        expect(response).to redirect_to(workflows_path)
        follow_redirect!
        expect(response.body).to include("Workflow was successfully deleted")
      end
    end
  end
end
