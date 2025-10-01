require 'rails_helper'

RSpec.describe "Workflow Usage Examples", type: :integration do
  # This test demonstrates how the Workflow feature can be used in a real application

  describe "Customer Support Workflow" do
    # Create the prompts that will be used in the workflow
    let!(:greeting_prompt) do
      PromptEngine::Prompt.create!(
        name: "Customer Greeting",
        slug: "customer-greeting",
        content: "Hello {{customer_name}}! Thank you for contacting our support team. I understand you're having an issue with: {{issue}}",
        status: "enabled"
      )
    end

    let!(:analysis_prompt) do
      PromptEngine::Prompt.create!(
        name: "Issue Analysis",
        slug: "issue-analysis",
        content: "Based on the customer interaction: {{output}} - Let me analyze this issue and provide a solution.",
        status: "enabled"
      )
    end

    let!(:solution_prompt) do
      PromptEngine::Prompt.create!(
        name: "Solution Provider",
        slug: "solution-provider",
        content: "Following the analysis: {{output}} - Here is a step-by-step solution to resolve this issue.",
        status: "enabled"
      )
    end

    # Create a workflow that chains these prompts together
    let!(:support_workflow) do
      PromptEngine::Workflow.create!(
        name: "customer-support",
        steps: {
          "1" => "customer-greeting",
          "2" => "issue-analysis",
          "3" => "solution-provider"
        }
      )
    end

    it "executes a complete customer support workflow" do
      # Mock the prompt rendering to return predictable output
      greeting_output = "Hello John! Thank you for contacting our support team. I understand you're having an issue with: Login problems"
      analysis_output = "Based on the customer interaction: #{greeting_output} - Let me analyze this issue and provide a solution."
      solution_output = "Following the analysis: #{analysis_output} - Here is a step-by-step solution to resolve this issue."

      call_count = 0
      allow_any_instance_of(PromptEngine::Prompt).to receive(:render) do |instance, **args|
        call_count += 1
        case call_count
        when 1
          expect(args[:customer_name]).to eq("John")
          expect(args[:issue]).to eq("Login problems")
          double(content: greeting_output)
        when 2
          expect(args[:output]).to eq(greeting_output)
          double(content: analysis_output)
        when 3
          expect(args[:output]).to eq(analysis_output)
          double(content: solution_output)
        end
      end

      # Execute the workflow using PromptEngine.workflow
      result = PromptEngine.workflow("customer-support",
        customer_name: "John",
        issue: "Login problems"
      )

      expect(result).to eq(solution_output)
      expect(call_count).to eq(3)
    end

    it "provides detailed step results with workflow_with_steps" do
      # Mock the prompt rendering
      greeting_output = "Greeting response"
      analysis_output = "Analysis response"
      solution_output = "Solution response"

      call_count = 0
      allow_any_instance_of(PromptEngine::Prompt).to receive(:render) do |instance, **args|
        call_count += 1
        case call_count
        when 1 then double(content: greeting_output)
        when 2 then double(content: analysis_output)
        when 3 then double(content: solution_output)
        end
      end

      # Execute the workflow with detailed results
      result = PromptEngine.workflow_with_steps("customer-support",
        customer_name: "John",
        issue: "Login problems"
      )

      expect(result).to include("customer-greeting_output" => greeting_output)
      expect(result).to include("issue-analysis_output" => analysis_output)
      expect(result).to include("solution-provider_output" => solution_output)
      expect(result).to include("result" => solution_output)
    end
  end

  describe "Content Generation Workflow" do
    let!(:outline_prompt) do
      PromptEngine::Prompt.create!(
        name: "Content Outline",
        slug: "content-outline",
        content: "Create an outline for a blog post about: {{topic}}",
        status: "enabled"
      )
    end

    let!(:writing_prompt) do
      PromptEngine::Prompt.create!(
        name: "Content Writer",
        slug: "content-writer",
        content: "Write a detailed blog post based on this outline: {{output}}",
        status: "enabled"
      )
    end

    let!(:review_prompt) do
      PromptEngine::Prompt.create!(
        name: "Content Reviewer",
        slug: "content-reviewer",
        content: "Review and improve this blog post: {{output}}",
        status: "enabled"
      )
    end

    let!(:content_workflow) do
      PromptEngine::Workflow.create!(
        name: "blog-post-creation",
        steps: {
          "1" => "content-outline",
          "2" => "content-writer",
          "3" => "content-reviewer"
        }
      )
    end

    it "creates a complete blog post through multiple steps" do
      # Mock the prompt outputs
      outline_output = "1. Introduction 2. Main Points 3. Conclusion"
      draft_output = "Here is a detailed blog post based on the outline..."
      final_output = "Here is the reviewed and improved blog post..."

      call_count = 0
      allow_any_instance_of(PromptEngine::Prompt).to receive(:render) do |instance, **args|
        call_count += 1
        case call_count
        when 1
          expect(args[:topic]).to eq("AI in Education")
          double(content: outline_output)
        when 2
          expect(args[:output]).to eq(outline_output)
          double(content: draft_output)
        when 3
          expect(args[:output]).to eq(draft_output)
          double(content: final_output)
        end
      end

      result = PromptEngine.workflow("blog-post-creation", topic: "AI in Education")
      expect(result).to eq(final_output)
    end
  end

  describe "Error Handling" do
    let!(:valid_prompt) do
      PromptEngine::Prompt.create!(
        name: "Valid Prompt",
        slug: "valid-prompt",
        content: "This is a valid prompt with {{input}}",
        status: "enabled"
      )
    end

    it "raises an error when workflow doesn't exist" do
      expect {
        PromptEngine.workflow("nonexistent-workflow", input: "test")
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "prevents creation of workflows with invalid prompt references" do
      expect {
        PromptEngine::Workflow.create!(
          name: "broken-workflow",
          steps: { "1" => "valid-prompt", "2" => "missing-prompt" }
        )
      }.to raise_error(ActiveRecord::RecordInvalid, /Referenced prompt 'missing-prompt' does not exist/)
    end
  end
end
