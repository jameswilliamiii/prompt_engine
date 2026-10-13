require "rails_helper"

RSpec.describe PromptEngine::Configuration do
  subject(:config) { described_class.new }

  describe "family settings" do
    {
      "claude-opus-5-5" => { provider: "anthropic", temperature: false, effort: true },
      "claude-haiku-5-5" => { provider: "anthropic", temperature: false, effort: true },
      "claude-sonnet-6" => { provider: "anthropic", temperature: false, effort: true },
      "claude-fable-5-1" => { provider: "anthropic", temperature: false, effort: true },
      "claude-opus-4-8" => { provider: "anthropic", temperature: false, effort: true },
      "claude-sonnet-4-6" => { provider: "anthropic", temperature: true, effort: true },
      "claude-haiku-4-5-20251001" => { provider: "anthropic", temperature: true, effort: false },
      "gpt-5.6-sol" => { provider: "openai", temperature: false, effort: false },
      "gpt-6" => { provider: "openai", temperature: false, effort: false },
      "o4-mini" => { provider: "openai", temperature: false, effort: false },
      "gpt-4.1" => { provider: "openai", temperature: true, effort: false },
      "mystery-model" => { provider: nil, temperature: true, effort: false }
    }.each do |model_id, expected|
      it "resolves #{model_id} without a catalog entry" do
        config.models = {}

        expect(config.provider_for(model_id)).to eq(expected[:provider])
        expect(config.supports_temperature?(model_id)).to eq(expected[:temperature])
        expect(config.supports_effort?(model_id)).to eq(expected[:effort])
      end
    end
  end

  it "lets a catalog entry override its family key by key" do
    config.models = { "claude-opus-5-5" => { label: "Opus", supports_effort: false } }

    expect(config.model_settings("claude-opus-5-5")).to include(provider: "anthropic", supports_temperature: false, supports_effort: false, label: "Opus")
  end

  it "accepts a callable model list" do
    calls = 0
    config.models = -> { calls += 1; { "gpt-5.6-sol" => { label: "GPT-5.6 Sol" } } }

    expect(config.models.keys).to eq([ "gpt-5.6-sol" ])
    expect(config.provider_for("gpt-5.6-sol")).to eq("openai")
    expect(calls).to eq(2)
  end

  it "uses host-defined families in place of the defaults" do
    config.model_families = [ [ /\Amy-/, { provider: "openai", supports_temperature: false } ] ]

    expect(config.provider_for("my-model")).to eq("openai")
    expect(config.provider_for("claude-opus-5-5")).to be_nil
  end
end
