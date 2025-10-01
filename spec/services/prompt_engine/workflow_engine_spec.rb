require 'rails_helper'

module PromptEngine
  RSpec.describe WorkflowEngine, type: :service do
  let!(:prompt1) { create(:prompt, slug: "greeting", content: "Hello {{name}}", status: "enabled") }
  let!(:prompt2) { create(:prompt, slug: "analysis", content: "Analyze: {{output}}", status: "enabled") }
    let(:workflow) do
      create(:workflow,
        name: "test-workflow",
        steps: { "1" => "greeting", "2" => "analysis" }
      )
    end
    let(:workflow_engine) { WorkflowEngine.new(workflow) }

    describe "#execute" do
      it "executes steps in correct order" do
        result = workflow_engine.execute(name: "John")
        expect(result).to include("Analyze:")
      end
    end

    describe "#execute_with_steps" do
      it "returns detailed results" do
        result = workflow_engine.execute_with_steps(name: "John")
        expect(result).to have_key("greeting_output")
        expect(result).to have_key("analysis_output")
        expect(result).to have_key("result")
        expect(result["greeting_output"]).to include("Hello John")
        # The second prompt should receive previous output as {{output}}
        expect(result["analysis_output"]).to include("Hello John")
      end
    end
  end
end
