require "rails_helper"

RSpec.describe "JSON Mode integration", type: :model do
  let(:prompt) { create(:prompt, json_mode: true, content: "List 2 items") }

  it "adds response_format to RubyLLM params when json_mode enabled" do
    rendered = prompt.render
    params = rendered.to_ruby_llm_params
    expect(params[:response_format]).to eq({ type: 'json_object' })
  end

  it "does not add response_format when json_mode disabled" do
    prompt.update!(json_mode: false)
    rendered = prompt.render
    params = rendered.to_ruby_llm_params
    expect(params[:response_format]).to be_nil
  end
end
