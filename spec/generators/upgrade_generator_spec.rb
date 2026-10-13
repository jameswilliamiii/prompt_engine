require "rails_helper"
require "generators/prompt_engine/upgrade/upgrade_generator"

RSpec.describe PromptEngine::Generators::UpgradeGenerator do
  let(:generator) { described_class.new([], {}, destination_root: Dir.mktmpdir) }

  before { allow(generator).to receive(:say) }

  it "copies the engine's migrations into the app" do
    expect(generator).to receive(:rake).with("prompt_engine:install:migrations")

    generator.invoke_all
  end

  it "points at this version's upgrade notes" do
    allow(generator).to receive(:rake)

    generator.invoke_all

    expect(generator).to have_received(:say).with(a_string_including("v#{PromptEngine::VERSION}/UPGRADING.md"))
  end
end
