require 'rails_helper'

RSpec.describe "Workflow Integration", type: :integration do
  describe "Creating and executing workflows" do
    let!(:greeting_prompt) do
      PromptEngine::Prompt.create!(
        name: "greeting",
        slug: "greeting",
        content: "Hello {{name}}! Welcome to our service.",
        status: "enabled"
      )
    end

    let!(:analysis_prompt) do
      PromptEngine::Prompt.create!(
        name: "analysis",
        slug: "analysis",
        content: "Analysis result: {{output}}",
        status: "enabled"
      )
    end

    it "allows creating a workflow with valid prompt references" do
      workflow = PromptEngine::Workflow.new(
        name: "customer-onboarding",
        steps: { "1" => "greeting", "2" => "analysis" }
      )
      expect(workflow).to be_valid
      expect(workflow.save).to be true
    end

    it "validates that referenced prompts exist" do
      workflow = PromptEngine::Workflow.new(
        name: "invalid-workflow",
        steps: { "1" => "nonexistent-prompt" }
      )
      expect(workflow).to_not be_valid
      expect(workflow.errors[:steps]).to include("Referenced prompt 'nonexistent-prompt' does not exist")
    end
  end

  describe "PromptEngine class methods" do
    let!(:greeting_prompt) do
      PromptEngine::Prompt.create!(
        name: "greeting",
        slug: "greeting",
        content: "Hello {{name}}!",
        status: "enabled"
      )
    end

    let!(:analysis_prompt) do
      PromptEngine::Prompt.create!(
        name: "analysis",
        slug: "analysis",
        content: "Analyze: {{output}}",
        status: "enabled"
      )
    end

    let!(:workflow) do
      PromptEngine::Workflow.create!(
        name: "test-workflow",
        steps: { "1" => "greeting", "2" => "analysis" }
      )
    end

    it "provides workflow execution through PromptEngine.workflow" do
      expect(PromptEngine).to respond_to(:workflow)
    end

    it "provides detailed workflow execution through PromptEngine.workflow_with_steps" do
      expect(PromptEngine).to respond_to(:workflow_with_steps)
    end
  end
end
