require 'rails_helper'

module PromptEngine
  RSpec.describe Workflow, type: :model do
    describe "validations" do
      it "requires a name" do
        workflow = Workflow.new(steps: { "1" => "test-prompt" })
        expect(workflow).to_not be_valid
        expect(workflow.errors[:name]).to include("can't be blank")
      end

      it "requires steps" do
        workflow = Workflow.new(name: "test-workflow")
        expect(workflow).to_not be_valid
        expect(workflow.errors[:steps]).to include("can't be blank")
      end

      it "requires unique names" do
        prompt = create(:prompt, slug: "test-prompt", status: "enabled")
        Workflow.create!(name: "test-workflow", steps: { "1" => "test-prompt" })
        workflow = Workflow.new(name: "test-workflow", steps: { "1" => "other-prompt" })
        expect(workflow).to_not be_valid
        expect(workflow.errors[:name]).to include("has already been taken")
      end

      it "validates prompt references exist" do
        workflow = Workflow.new(name: "test", steps: { "1" => "nonexistent-prompt" })
        expect(workflow).to_not be_valid
        expect(workflow.errors[:steps]).to include("Referenced prompt 'nonexistent-prompt' does not exist")
      end

      it "is valid with existing prompt references" do
        prompt = create(:prompt, slug: "existing-prompt", status: "enabled")
        workflow = Workflow.new(name: "test", steps: { "1" => "existing-prompt" })
        expect(workflow).to be_valid
      end
    end

    describe "#execute" do
      let!(:prompt1) { create(:prompt, slug: "step-1", content: "First step: {{input}}", status: "enabled") }
      let!(:prompt2) { create(:prompt, slug: "step-2", content: "Second step: {{output}}", status: "enabled") }
      let(:workflow) do
        Workflow.create!(
          name: "test-workflow",
          steps: { "1" => "step-1", "2" => "step-2" }
        )
      end

      it "executes workflow steps in order" do
        allow(PromptEngine).to receive(:render).and_call_original

        # Mock the rendered prompts to return simple content
        allow_any_instance_of(PromptEngine::Prompt).to receive(:render).and_return(
          double(content: "Step 1 output")
        )

        result = workflow.execute(input: "test input")
        expect(result).to eq("Step 1 output")
      end
    end

    describe "#execute_with_steps" do
      let!(:prompt1) { create(:prompt, slug: "greeting", content: "Hello {{name}}", status: "enabled") }
      let!(:prompt2) { create(:prompt, slug: "analysis", content: "Analyze: {{output}}", status: "enabled") }
      let(:workflow) do
        Workflow.create!(
          name: "customer-support",
          steps: { "1" => "greeting", "2" => "analysis" }
        )
      end

      it "returns detailed step results" do
        # Mock the rendered prompts
        allow_any_instance_of(PromptEngine::Prompt).to receive(:render).and_return(
          double(content: "Step output")
        )

        result = workflow.execute_with_steps(name: "John")

        expect(result).to include("greeting_output")
        expect(result).to include("analysis_output")
        expect(result).to include("result")
        expect(result["result"]).to eq("Step output")
      end
    end
  end
end
