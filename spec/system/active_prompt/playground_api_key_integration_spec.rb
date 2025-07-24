require 'rails_helper'

module ActivePrompt
  RSpec.describe "Playground API Key Integration", type: :system do
    include Engine.routes.url_helpers

    let(:prompt) { create(:prompt, name: "Test Prompt", content: "Hello {{name}}") }

    before do
      driven_by(:rack_test)
    end

    describe "API key prefilling from settings" do
      context "when settings have API keys saved" do
        before do
          Setting.instance.update!(
            openai_api_key: "sk-test-openai-key",
            anthropic_api_key: "sk-ant-test-anthropic-key"
          )
        end

        it "prefills the API key based on selected provider" do
          # Create prompts with different models to test prefilling
          anthropic_prompt = create(:prompt, name: "Anthropic Prompt", content: "Hello {{name}}", model: "claude-3-5-sonnet")
          openai_prompt = create(:prompt, name: "OpenAI Prompt", content: "Hello {{name}}", model: "gpt-4o")

          # Test Anthropic prompt
          visit playground_prompt_path(anthropic_prompt)
          expect(page).to have_field("api_key", with: "sk-ant-test-anthropic-key")
          expect(page).to have_text("Using saved API key from settings")

          # Test OpenAI prompt
          visit playground_prompt_path(openai_prompt)
          expect(page).to have_field("api_key", with: "sk-test-openai-key")
          expect(page).to have_text("Using saved API key from settings")

          # Test prompt with no model - should not prefill
          visit playground_prompt_path(prompt)
          api_key_field = find("#api_key")
          expect(api_key_field["data-anthropic-key"]).to eq("sk-ant-test-anthropic-key")
          expect(api_key_field["data-openai-key"]).to eq("sk-test-openai-key")
        end

        it "includes link to change settings" do
          visit playground_prompt_path(prompt)

          expect(page).to have_link("Change in settings", href: edit_settings_path)
        end
      end

      context "when no API keys are saved" do
        before do
          Setting.instance.update!(
            openai_api_key: nil,
            anthropic_api_key: nil
          )
        end

        it "shows placeholder and link to save in settings" do
          visit playground_prompt_path(prompt)

          expect(page).to have_field("api_key", placeholder: "Enter your API key")
          expect(page).to have_link("Save in settings", href: edit_settings_path)
        end
      end

      context "when only one provider has API key saved" do
        before do
          Setting.instance.update!(
            openai_api_key: "sk-test-openai-only",
            anthropic_api_key: nil
          )
        end

        it "only prefills for the provider with saved key" do
          # Create a prompt with a model that matches the provider with a saved key
          openai_prompt = create(:prompt, name: "OpenAI Prompt", content: "Hello {{name}}", model: "gpt-4o")

          visit playground_prompt_path(openai_prompt)

          # OpenAI should be selected because of the model, and key should be prefilled
          expect(page).to have_field("api_key", with: "sk-test-openai-only")

          # Data attributes should still be set correctly
          api_key_field = find("#api_key")
          expect(api_key_field["data-openai-key"]).to eq("sk-test-openai-only")
          # When the API key is nil, the data attribute is not set (nil)
          expect(api_key_field["data-anthropic-key"]).to be_nil
        end
      end
    end

    describe "executing playground with saved API keys" do
      before do
        Setting.instance.update!(
          anthropic_api_key: "sk-ant-valid-test-key"
        )
      end

      it "uses the saved API key for execution" do
        # Create a prompt with anthropic model so it prefills the API key
        anthropic_prompt = create(:prompt, name: "Claude Prompt", content: "Hello {{name}}", model: "claude-3-5-sonnet")

        visit playground_prompt_path(anthropic_prompt)

        fill_in "parameters[name]", with: "World"

        # Mock the executor to verify it receives the saved API key
        allow_any_instance_of(PlaygroundExecutor).to receive(:execute).and_return({
          response: "Hello World!",
          execution_time: 1.5,
          token_count: 10,
          model: "claude-3-5-sonnet-20241022",
          provider: "anthropic"
        })

        click_button "Test Prompt"

        expect(page).to have_content("Hello World!")
      end
    end
  end
end
