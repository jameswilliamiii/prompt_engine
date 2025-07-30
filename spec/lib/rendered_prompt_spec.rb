require "rails_helper"

module PromptEngine
  RSpec.describe RenderedPrompt do
    let(:prompt) do
      create(:prompt,
        slug: "test-prompt",
        content: "Hello {{name}}",
        system_message: "You are a helpful assistant",
        model: "gpt-4",
        temperature: 0.7,
        max_tokens: 1000,
        status: "active"
      )
    end

    let(:rendered_data) do
      {
        content: "Hello Alice",
        system_message: "You are a helpful assistant",
        model: "gpt-4",
        temperature: 0.7,
        max_tokens: 1000,
        parameters_used: { "name" => "Alice" },
        version_number: 1
      }
    end

    let(:overrides) do
      {
        model: "gpt-4-turbo",
        temperature: 0.9,
        status: "draft"
      }
    end

    let(:rendered_prompt) { described_class.new(prompt, rendered_data, overrides) }

    describe "#options" do
      it "returns a copy of the overrides hash" do
        expect(rendered_prompt.options).to eq(overrides)
        expect(rendered_prompt.options).not_to be(overrides) # Should be a copy
      end

      it "returns empty hash when no overrides provided" do
        prompt_without_overrides = described_class.new(prompt, rendered_data)
        expect(prompt_without_overrides.options).to eq({})
      end
    end

    describe "#status" do
      it "returns the status from overrides if provided" do
        expect(rendered_prompt.status).to eq("draft")
      end

      it "returns the prompt's status if not overridden" do
        prompt_without_status = described_class.new(prompt, rendered_data, { model: "gpt-4" })
        expect(prompt_without_status.status).to eq("active")
      end
    end

    describe "#version" do
      it "returns the version number from rendered data" do
        expect(rendered_prompt.version).to eq(1)
      end

      it "returns nil if no version number" do
        data_without_version = rendered_data.except(:version_number)
        prompt_no_version = described_class.new(prompt, data_without_version)
        expect(prompt_no_version.version).to be_nil
      end
    end

    describe "#model" do
      it "returns overridden model when provided" do
        expect(rendered_prompt.model).to eq("gpt-4-turbo")
      end

      it "returns rendered data model when not overridden" do
        prompt_no_override = described_class.new(prompt, rendered_data, {})
        expect(prompt_no_override.model).to eq("gpt-4")
      end
    end

    describe "#temperature" do
      it "returns overridden temperature when provided" do
        expect(rendered_prompt.temperature).to eq(0.9)
      end

      it "returns rendered data temperature when not overridden" do
        prompt_no_override = described_class.new(prompt, rendered_data, {})
        expect(prompt_no_override.temperature).to eq(0.7)
      end
    end

    describe "#max_tokens" do
      it "returns overridden max_tokens when provided" do
        with_max_tokens = described_class.new(prompt, rendered_data, { max_tokens: 2000 })
        expect(with_max_tokens.max_tokens).to eq(2000)
      end

      it "returns rendered data max_tokens when not overridden" do
        expect(rendered_prompt.max_tokens).to eq(1000)
      end
    end

    describe "#system_message" do
      it "returns overridden system_message when provided" do
        with_system = described_class.new(prompt, rendered_data, { system_message: "New system message" })
        expect(with_system.system_message).to eq("New system message")
      end

      it "returns rendered data system_message when not overridden" do
        expect(rendered_prompt.system_message).to eq("You are a helpful assistant")
      end
    end

    describe "#to_h" do
      it "includes all the expected keys" do
        hash = rendered_prompt.to_h
        expect(hash).to include(
          content: "Hello Alice",
          system_message: "You are a helpful assistant",
          model: "gpt-4-turbo",
          temperature: 0.9,
          max_tokens: 1000,
          status: "draft",
          version: 1,
          options: overrides,
          parameters: { "name" => "Alice" }
        )
      end
    end

    describe "backward compatibility" do
      it "still exposes content as attr_reader" do
        expect(rendered_prompt.content).to eq("Hello Alice")
      end

      it "still exposes overrides as attr_reader" do
        expect(rendered_prompt.overrides).to eq(overrides)
      end

      it "still exposes version_number as attr_reader" do
        expect(rendered_prompt.version_number).to eq(1)
      end
    end
  end
end