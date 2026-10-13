require "rails_helper"

module PromptEngine
  RSpec.describe "Playground with status filtering", type: :request do
    include Engine.routes.url_helpers

    let!(:active_prompt) do
      create(:prompt,
        name: "Active Test Prompt",
        slug: "test-prompt",
        content: "Active: {{message}}",
        status: "active"
      ).tap(&:sync_parameters!)
    end

    let!(:draft_prompt) do
      create(:prompt,
        name: "Draft Test Prompt",
        slug: "draft-test-prompt",
        content: "Draft: {{message}}",
        status: "draft"
      ).tap(&:sync_parameters!)
    end

    describe "GET playground with status-filtered prompts" do
      it "can access active prompts playground" do
        get playground_prompt_path(active_prompt)
        expect(response).to be_successful
        expect(response.body).to include("Active Test Prompt")
      end

      it "can access draft prompts playground" do
        get playground_prompt_path(draft_prompt)
        expect(response).to be_successful
        expect(response.body).to include("Draft Test Prompt")
      end
    end

    describe "POST execute in playground" do
      before do
        openai_body = {
          id: "chatcmpl-1", object: "chat.completion", model: "gpt-4o",
          choices: [ { index: 0, message: { role: "assistant", content: "Test response" }, finish_reason: "stop" } ],
          usage: { prompt_tokens: 5, completion_tokens: 5, total_tokens: 10 }
        }
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(status: 200, body: openai_body.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "executes draft prompts in playground" do
        post playground_prompt_path(draft_prompt), params: {
          model: "gpt-4o",
          api_key: "test-key",
          parameters: { message: "Hello" }
        }

        expect(response).to be_successful
        result = PlaygroundRunResult.last
        expect(result.prompt_version.prompt).to eq(draft_prompt)
      end

      it "executes active prompts in playground" do
        post playground_prompt_path(active_prompt), params: {
          model: "gpt-4o",
          api_key: "test-key",
          parameters: { message: "World" }
        }

        expect(response).to be_successful
        result = PlaygroundRunResult.last
        expect(result.prompt_version.prompt).to eq(active_prompt)
      end
    end

    describe "Playground UI considerations" do
      it "shows prompt status in playground header" do
        get playground_prompt_path(draft_prompt)

        # The playground should indicate this is a draft
        expect(response.body).to include("Draft Test Prompt")
        expect(response.body).to include(draft_prompt.status.capitalize)
      end
    end
  end
end
