require "rails_helper"

RSpec.describe PromptEngine::WorkflowEngine, type: :service do
  let!(:prompt1) { create(:prompt, slug: "step-one", content: "Return a JSON object with a key 'value'", json_mode: true) }
  let!(:workflow) { PromptEngine::Workflow.create!(name: "json-workflow", steps: { "1" => "step-one" }) }

  it "parses JSON output when json_mode enabled" do
    engine = described_class.new(workflow)
    allow_any_instance_of(PromptEngine::PlaygroundExecutor).to receive(:execute).and_return({ response: '{"value": 123}', execution_time: 0.01, token_count: 0, model: 'gpt-4o', provider: 'openai' })
    result = engine.execute_with_steps(initial_input: "seed", provider: 'openai', api_key: 'sk-test-123')
    step_output = result[:steps].first[:output]
    expect(step_output).to be_a(Hash)
    expect(step_output["value"]).to eq(123)
  end
end
