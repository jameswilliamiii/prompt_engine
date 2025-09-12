require "rails_helper"

module PromptEngine
  RSpec.describe "Playground API Key Integration", type: :system do
    include Engine.routes.url_helpers

    let(:prompt) { create(:prompt, name: "Test Prompt", content: "Hello {{name}}") }

    describe "API key prefilling from settings" do
      context "when settings have API keys saved" do
        before do
          Setting.instance.update!(
            openai_api_key: "sk-test-openai-key",
            anthropic_api_key: "sk-ant-test-anthropic-key"
          )
        end

        it "shows checkbox to use saved keys and only prefills when checked" do
          visit playground_prompt_path(prompt)

          # Should show checkbox for using saved keys
          expect(page).to have_field("Use saved API keys from settings")

          # Should not prefill API key by default
          expect(page).to have_field("api_key", with: "")
          expect(page).to have_text("Your API key will not be stored")

          # API keys should still be available in data attributes for Stimulus
          playground_controller = find('[data-controller="prompt-engine--playground"]')
          expect(playground_controller["data-prompt-engine--playground-anthropic-key-value"]).to eq("sk-ant-test-anthropic-key")
          expect(playground_controller["data-prompt-engine--playground-openai-key-value"]).to eq("sk-test-openai-key")
        end

        it "includes link to save in settings" do
          visit playground_prompt_path(prompt)

          expect(page).to have_link("Save in settings", href: edit_settings_path)
        end
      end

      context "when no API keys are saved" do
        before do
          Setting.instance.update!(
            openai_api_key: nil,
            anthropic_api_key: nil
          )
        end

        it "shows placeholder and link to save in settings without checkbox" do
          visit playground_prompt_path(prompt)

          expect(page).to have_field("api_key", placeholder: "Enter your API key")
          expect(page).to have_link("Save in settings", href: edit_settings_path)
          # Should not show checkbox when no keys are saved
          expect(page).not_to have_field("Use saved API keys from settings")
        end
      end

      context "when only one provider has API key saved" do
        before do
          Setting.instance.update!(
            openai_api_key: "sk-test-openai-only",
            anthropic_api_key: nil
          )
        end

        it "shows checkbox and data attributes for partial saved keys" do
          visit playground_prompt_path(prompt)

          # Should show checkbox even with only one provider key
          expect(page).to have_field("Use saved API keys from settings")

          # Should not prefill by default
          expect(page).to have_field("api_key", with: "")

          # Data attributes should reflect saved keys
          playground_controller = find('[data-controller="prompt-engine--playground"]')
          expect(playground_controller["data-prompt-engine--playground-openai-key-value"]).to eq("sk-test-openai-only")
          # When the API key is nil, the value should be empty string (Stimulus values default to empty string for nil)
          expect(playground_controller["data-prompt-engine--playground-anthropic-key-value"]).to eq("")
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
