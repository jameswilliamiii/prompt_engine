require "rails_helper"

RSpec.describe PromptEngine::RenderedPrompt, type: :model do
  let(:prompt) { create(:prompt, slug: "test-prompt") }
  let(:rendered_data) do
    {
      content: "Hello John from Acme Corp!",
      system_message: "You are a helpful assistant",
      model: "gpt-4",
      temperature: 0.7,
      max_tokens: 1000,
      parameters_used: {
        "user_name" => "John",
        "company_name" => "Acme Corp",
        "user_id" => 123,
        "is_premium" => true
      },
      version_number: 1
    }
  end
  let(:overrides) { {} }
  let(:rendered_prompt) { described_class.new(prompt, rendered_data, overrides) }

  describe "basic attributes" do
    it "exposes content, system_message, and model settings" do
      expect(rendered_prompt.content).to eq("Hello John from Acme Corp!")
      expect(rendered_prompt.system_message).to eq("You are a helpful assistant")
      expect(rendered_prompt.model).to eq("gpt-4")
      expect(rendered_prompt.temperature).to eq(0.7)
      expect(rendered_prompt.max_tokens).to eq(1000)
    end
  end

  describe "parameter access" do
    describe "#parameters" do
      it "returns the full parameters hash" do
        expect(rendered_prompt.parameters).to eq({
          "user_name" => "John",
          "company_name" => "Acme Corp",
          "user_id" => 123,
          "is_premium" => true
        })
      end
    end

    describe "#parameter" do
      it "returns the value for a given parameter key" do
        expect(rendered_prompt.parameter(:user_name)).to eq("John")
        expect(rendered_prompt.parameter("user_name")).to eq("John")
        expect(rendered_prompt.parameter(:company_name)).to eq("Acme Corp")
        expect(rendered_prompt.parameter(:user_id)).to eq(123)
        expect(rendered_prompt.parameter(:is_premium)).to eq(true)
      end

      it "returns nil for non-existent parameters" do
        expect(rendered_prompt.parameter(:non_existent)).to be_nil
        expect(rendered_prompt.parameter("undefined")).to be_nil
      end

      it "handles symbol and string keys" do
        expect(rendered_prompt.parameter(:user_name)).to eq("John")
        expect(rendered_prompt.parameter("user_name")).to eq("John")
      end
    end

    describe "#parameter_names" do
      it "returns an array of parameter names" do
        expect(rendered_prompt.parameter_names).to match_array([
          "user_name", "company_name", "user_id", "is_premium"
        ])
      end
    end

    describe "#parameter_values" do
      it "returns an array of parameter values" do
        expect(rendered_prompt.parameter_values).to match_array([
          "John", "Acme Corp", 123, true
        ])
      end
    end

    describe "#parameter?" do
      it "returns true for existing parameters" do
        expect(rendered_prompt.parameter?(:user_name)).to be true
        expect(rendered_prompt.parameter?("company_name")).to be true
      end

      it "returns false for non-existent parameters" do
        expect(rendered_prompt.parameter?(:non_existent)).to be false
        expect(rendered_prompt.parameter?("undefined")).to be false
      end
    end
  end

  describe "#to_h" do
    it "includes parameters in the hash representation" do
      hash = rendered_prompt.to_h
      expect(hash[:parameters]).to eq({
        "user_name" => "John",
        "company_name" => "Acme Corp",
        "user_id" => 123,
        "is_premium" => true
      })
      expect(hash).to include(
        content: "Hello John from Acme Corp!",
        system_message: "You are a helpful assistant",
        model: "gpt-4",
        temperature: 0.7,
        max_tokens: 1000
      )
    end
  end

  describe "#inspect" do
    it "includes parameter names in the inspect output" do
      output = rendered_prompt.inspect
      expect(output).to include("prompt=test-prompt")
      expect(output).to include("version=1")
      expect(output).to include("parameters=")
      expect(output).to include("user_name")
      expect(output).to include("company_name")
    end

    context "with overrides" do
      let(:overrides) { { model: "gpt-3.5-turbo", temperature: 0.5 } }

      it "includes overrides in the inspect output" do
        output = rendered_prompt.inspect
        expect(output).to include("overrides=[:model, :temperature]")
      end
    end
  end

  describe "with no parameters" do
    let(:rendered_data) do
      super().merge(parameters_used: nil)
    end

    it "handles nil parameters gracefully" do
      expect(rendered_prompt.parameters).to eq({})
      expect(rendered_prompt.parameter_names).to eq([])
      expect(rendered_prompt.parameter_values).to eq([])
      expect(rendered_prompt.parameter?(:anything)).to be false
    end
  end

  describe "prompt access" do
    it "provides access to the original prompt object" do
      expect(rendered_prompt.prompt).to eq(prompt)
      expect(rendered_prompt.prompt.slug).to eq("test-prompt")
    end
  end

  describe "overrides" do
    let(:overrides) { { model: "gpt-3.5-turbo", temperature: 0.5 } }

    it "applies overrides to model settings" do
      expect(rendered_prompt.model).to eq("gpt-3.5-turbo")
      expect(rendered_prompt.temperature).to eq(0.5)
      expect(rendered_prompt.max_tokens).to eq(1000) # not overridden
    end
  end
end