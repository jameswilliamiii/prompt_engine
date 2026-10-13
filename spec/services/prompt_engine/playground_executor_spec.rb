require "rails_helper"

RSpec.describe PromptEngine::PlaygroundExecutor, type: :service do
  let(:models) do
    {
      "gpt-4o" => { provider: "openai", label: "GPT-4o" },
      "gpt-5" => { provider: "openai", label: "GPT-5" },
      "claude-sonnet-4-6" => { provider: "anthropic", label: "Claude Sonnet 4.6" },
      "claude-opus-5-5" => { provider: "anthropic", label: "Claude Opus 5.5", supports_temperature: false, supports_effort: true }
    }
  end
  let(:prompt) do
    create(:prompt,
      model: model,
      content: "Tell me about {{topic}}",
      system_message: "You are a helpful assistant",
      temperature: 0.8,
      max_tokens: 150,
      effort: "high")
  end
  let(:model) { "claude-opus-5-5" }
  let(:executor) do
    described_class.new(prompt: prompt, model: model, api_key: "test-key", parameters: { topic: "ruby" })
  end

  let(:anthropic_body) do
    {
      id: "msg_1", type: "message", role: "assistant", model: model,
      content: [ { type: "text", text: "Ruby is a language." } ],
      stop_reason: "end_turn",
      usage: { input_tokens: 10, output_tokens: 5 }
    }
  end
  let(:openai_body) do
    {
      id: "chatcmpl-1", object: "chat.completion", model: "gpt-4o",
      choices: [ { index: 0, message: { role: "assistant", content: "Ruby is a language." }, finish_reason: "stop" } ],
      usage: { prompt_tokens: 10, completion_tokens: 5, total_tokens: 15 }
    }
  end

  def stub_anthropic(body: anthropic_body, status: 200)
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_openai(body: openai_body)
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def sent_body
    payload = nil
    expect(WebMock).to have_requested(:post, /api\.(anthropic|openai)\.com/).with { |request| payload = JSON.parse(request.body) }
    payload
  end

  before { allow(PromptEngine.config).to receive(:models).and_return(models) }

  describe "#execute" do
    context "with a model that takes effort and rejects temperature" do
      before { stub_anthropic }

      it "returns the response, provider, token count and the settings it sent" do
        result = executor.execute

        expect(result).to include(
          response: "Ruby is a language.", model: model, provider: "anthropic", token_count: 15,
          temperature: nil, max_tokens: 150, effort: "high"
        )
      end

      it "sends effort, max_tokens, the system message and the rendered content" do
        executor.execute

        expect(sent_body).to include(
          "max_tokens" => 150,
          "output_config" => { "effort" => "high" },
          "messages" => [ { "role" => "user", "content" => [ { "type" => "text", "text" => "Tell me about ruby" } ] } ]
        )
      end

      it "leaves out a temperature saved for a different model" do
        gpt_prompt = create(:prompt, model: "gpt-4o", content: "Tell me about {{topic}}", temperature: 0.8)
        described_class.new(prompt: gpt_prompt, model: model, api_key: "test-key", parameters: { topic: "ruby" }).execute

        expect(sent_body).not_to have_key("temperature")
      end

      it "sends the key on this request without replacing the global one" do
        expect { executor.execute }.not_to change { RubyLLM.config.anthropic_api_key }
        expect(WebMock).to have_requested(:post, "https://api.anthropic.com/v1/messages").with(headers: { "x-api-key" => "test-key" })
      end
    end

    context "with a model that takes temperature but not effort" do
      let(:model) { "gpt-4o" }

      before { stub_openai }

      it "sends temperature and max_completion_tokens, and leaves effort out" do
        executor.execute

        expect(sent_body).to include("temperature" => 0.8, "max_completion_tokens" => 150)
        expect(sent_body).not_to have_key("max_tokens")
        expect(sent_body).not_to have_key("output_config")
      end
    end

    context "with an OpenAI reasoning model" do
      let(:model) { "gpt-5" }

      before { stub_openai(body: openai_body.merge(model: "gpt-5")) }

      it "leaves temperature out, from the model's family settings" do
        prompt.update_columns(temperature: 0.8)
        executor.execute

        expect(sent_body).not_to have_key("temperature")
      end

      it "lets ruby_llm adjust a temperature the catalog lets through" do
        models["gpt-5"] = { label: "GPT-5", supports_temperature: true }
        prompt.update_columns(temperature: 0.8)
        executor.execute

        expect(sent_body).to include("temperature" => 1.0)
      end
    end

    context "when the response stops early" do
      it "reports a refusal" do
        stub_anthropic(body: anthropic_body.merge(stop_reason: "refusal", content: []))

        expect { executor.execute }.to raise_error(described_class::IncompleteResponseError, /declined/)
      end

      it "reports a cutoff at max_tokens" do
        stub_anthropic(body: anthropic_body.merge(stop_reason: "max_tokens"))

        expect { executor.execute }.to raise_error(described_class::IncompleteResponseError, /Max Tokens/)
      end
    end

    context "when the provider returns an error" do
      it "reports an invalid key" do
        stub_anthropic(status: 401, body: { type: "error", error: { type: "authentication_error", message: "invalid x-api-key" } })

        expect { executor.execute }.to raise_error(RuntimeError, "Invalid API key")
      end

      it "reports a rate limit" do
        stub_anthropic(status: 429, body: { type: "error", error: { type: "rate_limit_error", message: "slow down" } })

        expect { executor.execute }.to raise_error(RuntimeError, "Rate limit exceeded. Please try again later.")
      end

      it "passes a bad request's message through" do
        stub_anthropic(status: 400, body: { type: "error", error: { type: "invalid_request_error", message: "temperature is not supported" } })

        expect { executor.execute }.to raise_error(RuntimeError, /temperature is not supported/)
      end
    end

    context "with invalid inputs" do
      it "rejects a blank model" do
        executor = described_class.new(prompt: prompt, model: "", api_key: "key")

        expect { executor.execute }.to raise_error(ArgumentError, "Model is required")
      end

      it "rejects a blank API key" do
        executor = described_class.new(prompt: prompt, model: model, api_key: "")

        expect { executor.execute }.to raise_error(ArgumentError, "API key is required")
      end

      it "rejects a model outside the catalog" do
        executor = described_class.new(prompt: prompt, model: "unknown-model", api_key: "key")

        expect { executor.execute }.to raise_error(ArgumentError, "Unknown model: unknown-model")
      end
    end
  end
end
