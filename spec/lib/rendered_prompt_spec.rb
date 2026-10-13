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

    describe "#messages" do
      context "with system message" do
        let(:rendered_data) do
          {
            content: "Hello world",
            system_message: "You are a helpful assistant",
            model: "gpt-4",
            temperature: 0.7,
            max_tokens: 1000,
            parameters_used: {},
            version_number: 1
          }
        end

        it "returns array with system and user messages in correct order" do
          prompt_with_system = described_class.new(prompt, rendered_data)
          messages = prompt_with_system.messages

          expect(messages).to eq([
            { role: "system", content: "You are a helpful assistant" },
            { role: "user", content: "Hello world" }
          ])
        end

        it "uses system message from overrides when provided" do
          overrides_with_system = { system_message: "Override system message" }
          prompt_with_override = described_class.new(prompt, rendered_data, overrides_with_system)
          messages = prompt_with_override.messages

          expect(messages).to eq([
            { role: "system", content: "Override system message" },
            { role: "user", content: "Hello world" }
          ])
        end
      end

      context "without system message" do
        let(:rendered_data_no_system) do
          {
            content: "Hello world",
            system_message: nil,
            model: "gpt-4",
            temperature: 0.7,
            max_tokens: 1000,
            parameters_used: {},
            version_number: 1
          }
        end

        it "returns array with only user message when system_message is nil" do
          prompt_no_system = described_class.new(prompt, rendered_data_no_system)
          messages = prompt_no_system.messages

          expect(messages).to eq([
            { role: "user", content: "Hello world" }
          ])
        end

        it "returns array with only user message when system_message is empty string" do
          data_empty_system = rendered_data_no_system.merge(system_message: "")
          prompt_empty_system = described_class.new(prompt, data_empty_system)
          messages = prompt_empty_system.messages

          expect(messages).to eq([
            { role: "user", content: "Hello world" }
          ])
        end

        it "returns array with only user message when system_message is whitespace" do
          data_whitespace_system = rendered_data_no_system.merge(system_message: "   ")
          prompt_whitespace_system = described_class.new(prompt, data_whitespace_system)
          messages = prompt_whitespace_system.messages

          expect(messages).to eq([
            { role: "user", content: "Hello world" }
          ])
        end
      end

      context "with different content" do
        it "always includes the content as user message" do
          data_with_content = rendered_data.merge(content: "Complex prompt with {{variables}}")
          prompt_complex = described_class.new(prompt, data_with_content)
          messages = prompt_complex.messages

          expect(messages.last).to eq({ role: "user", content: "Complex prompt with {{variables}}" })
        end
      end
    end

    describe "#to_openai_params" do
      context "with all parameters provided" do
        let(:rendered_data) do
          {
            content: "Test prompt",
            system_message: "You are helpful",
            model: "gpt-4",
            temperature: 0.7,
            max_tokens: 1000,
            parameters_used: {},
            version_number: 1
          }
        end

        it "returns OpenAI-formatted parameters with all fields" do
          prompt_full = described_class.new(prompt, rendered_data)
          params = prompt_full.to_openai_params

          expect(params).to eq({
            model: "gpt-4",
            messages: [
              { role: "system", content: "You are helpful" },
              { role: "user", content: "Test prompt" }
            ],
            temperature: 0.7,
            max_completion_tokens: 1000
          })
        end

        it "uses the messages method to build messages array" do
          prompt_test = described_class.new(prompt, rendered_data)
          expect(prompt_test).to receive(:messages).and_call_original
          prompt_test.to_openai_params
        end
      end

      context "with nil model" do
        let(:rendered_data_no_model) do
          {
            content: "Test prompt",
            system_message: "System",
            model: nil,
            temperature: 0.5,
            max_tokens: 500,
            parameters_used: {},
            version_number: 1
          }
        end

        it "leaves the model out when it is nil" do
          prompt_no_model = described_class.new(prompt, rendered_data_no_model)
          params = prompt_no_model.to_openai_params

          expect(params).not_to have_key(:model)
        end
      end

      context "with nil values" do
        let(:rendered_data_with_nils) do
          {
            content: "Test prompt",
            system_message: nil,
            model: "gpt-3.5-turbo",
            temperature: nil,
            max_tokens: nil,
            parameters_used: {},
            version_number: 1
          }
        end

        it "removes nil values with compact" do
          prompt_with_nils = described_class.new(prompt, rendered_data_with_nils)
          params = prompt_with_nils.to_openai_params

          expect(params).to eq({
            model: "gpt-3.5-turbo",
            messages: [
              { role: "user", content: "Test prompt" }
            ]
          })
          expect(params).not_to have_key(:temperature)
          expect(params).not_to have_key(:max_tokens)
        end
      end

      context "with additional options" do
        it "merges additional options into the parameters" do
          prompt_test = described_class.new(prompt, rendered_data)
          params = prompt_test.to_openai_params(
            tools: [ { type: "function", function: { name: "test" } } ],
            stream: true,
            response_format: { type: "json_object" }
          )

          expect(params).to include(
            model: "gpt-4",
            messages: anything,
            temperature: 0.7,
            max_completion_tokens: 1000,
            tools: [ { type: "function", function: { name: "test" } } ],
            stream: true,
            response_format: { type: "json_object" }
          )
        end

        it "allows additional options to override base parameters" do
          prompt_test = described_class.new(prompt, rendered_data)
          params = prompt_test.to_openai_params(
            model: "gpt-4-turbo",
            temperature: 0.9
          )

          expect(params[:model]).to eq("gpt-4-turbo")
          expect(params[:temperature]).to eq(0.9)
        end
      end

      context "with overrides from constructor" do
        let(:test_rendered_data) do
          {
            content: "Test prompt",
            system_message: "Original system",
            model: "gpt-4",
            temperature: 0.7,
            max_tokens: 1000,
            parameters_used: {},
            version_number: 1
          }
        end

        let(:test_overrides) do
          {
            model: "gpt-4-turbo",
            temperature: 0.3,
            max_tokens: 2000,
            system_message: "Override system"
          }
        end

        it "uses override values in the output" do
          prompt_with_overrides = described_class.new(prompt, test_rendered_data, test_overrides)
          params = prompt_with_overrides.to_openai_params

          expect(params).to eq({
            model: "gpt-4-turbo",
            messages: [
              { role: "system", content: "Override system" },
              { role: "user", content: "Test prompt" }
            ],
            temperature: 0.3,
            max_completion_tokens: 2000
          })
        end
      end
    end

    describe "#to_ruby_llm_params" do
      context "with all parameters provided" do
        let(:rendered_data) do
          {
            content: "Test prompt",
            system_message: "You are helpful",
            model: "claude-3-opus",
            temperature: 0.7,
            max_tokens: 1000,
            parameters_used: {},
            version_number: 1
          }
        end

        it "returns RubyLLM-formatted parameters with all fields" do
          prompt_full = described_class.new(prompt, rendered_data)
          params = prompt_full.to_ruby_llm_params

          expect(params).to eq({
            messages: [
              { role: "system", content: "You are helpful" },
              { role: "user", content: "Test prompt" }
            ],
            model: "claude-3-opus",
            temperature: 0.7,
            max_tokens: 1000
          })
        end

        it "has messages as the first key in the hash" do
          prompt_test = described_class.new(prompt, rendered_data)
          params = prompt_test.to_ruby_llm_params

          expect(params.keys.first).to eq(:messages)
        end

        it "uses the messages method to build messages array" do
          prompt_test = described_class.new(prompt, rendered_data)
          expect(prompt_test).to receive(:messages).and_call_original
          prompt_test.to_ruby_llm_params
        end
      end

      context "with nil model" do
        let(:rendered_data_no_model) do
          {
            content: "Test prompt",
            system_message: "System",
            model: nil,
            temperature: 0.5,
            max_tokens: 500,
            parameters_used: {},
            version_number: 1
          }
        end

        it "leaves the model out when it is nil" do
          prompt_no_model = described_class.new(prompt, rendered_data_no_model)
          params = prompt_no_model.to_ruby_llm_params

          expect(params).not_to have_key(:model)
        end
      end

      context "with nil values" do
        let(:rendered_data_with_nils) do
          {
            content: "Test prompt",
            system_message: nil,
            model: "claude-3-sonnet",
            temperature: nil,
            max_tokens: nil,
            parameters_used: {},
            version_number: 1
          }
        end

        it "removes nil values with compact" do
          prompt_with_nils = described_class.new(prompt, rendered_data_with_nils)
          params = prompt_with_nils.to_ruby_llm_params

          expect(params).to eq({
            messages: [
              { role: "user", content: "Test prompt" }
            ],
            model: "claude-3-sonnet"
          })
          expect(params).not_to have_key(:temperature)
          expect(params).not_to have_key(:max_tokens)
        end
      end

      context "with additional options" do
        let(:test_rendered_data) do
          {
            content: "Test prompt",
            system_message: "You are helpful",
            model: "claude-3-opus",
            temperature: 0.7,
            max_tokens: 1000,
            parameters_used: {},
            version_number: 1
          }
        end

        it "merges additional options into the parameters" do
          prompt_test = described_class.new(prompt, test_rendered_data)
          params = prompt_test.to_ruby_llm_params(
            stop_sequences: [ "\\n\\n" ],
            top_p: 0.9,
            metadata: { user_id: 123 }
          )

          expect(params).to include(
            messages: anything,
            model: "claude-3-opus",
            temperature: 0.7,
            max_tokens: 1000,
            stop_sequences: [ "\\n\\n" ],
            top_p: 0.9,
            metadata: { user_id: 123 }
          )
        end

        it "allows additional options to override base parameters" do
          prompt_test = described_class.new(prompt, test_rendered_data)
          params = prompt_test.to_ruby_llm_params(
            model: "claude-3-haiku",
            temperature: 0.2
          )

          expect(params[:model]).to eq("claude-3-haiku")
          expect(params[:temperature]).to eq(0.2)
        end
      end

      context "with overrides from constructor" do
        let(:test_rendered_data) do
          {
            content: "Test prompt",
            system_message: "Original system",
            model: "claude-3-opus",
            temperature: 0.7,
            max_tokens: 1000,
            parameters_used: {},
            version_number: 1
          }
        end

        let(:test_overrides) do
          {
            model: "claude-3-sonnet",
            temperature: 0.4,
            max_tokens: 2000,
            system_message: "Override system"
          }
        end

        it "uses override values in the output" do
          prompt_with_overrides = described_class.new(prompt, test_rendered_data, test_overrides)
          params = prompt_with_overrides.to_ruby_llm_params

          expect(params).to eq({
            messages: [
              { role: "system", content: "Override system" },
              { role: "user", content: "Test prompt" }
            ],
            model: "claude-3-sonnet",
            temperature: 0.4,
            max_tokens: 2000
          })
        end
      end

      context "compatibility with Anthropic format" do
        it "produces the same structure as expected by Anthropic clients" do
          prompt_test = described_class.new(prompt, rendered_data)
          params = prompt_test.to_ruby_llm_params

          # Anthropic expects the same format
          expect(params).to have_key(:messages)
          expect(params).to have_key(:model)
          expect(params[:messages]).to be_an(Array)
          expect(params[:messages].first).to have_key(:role)
          expect(params[:messages].first).to have_key(:content)
        end
      end
    end

    describe "model capabilities" do
      let(:models) do
        {
          "gpt-4o" => { provider: "openai", label: "GPT-4o" },
          "claude-opus-5-5" => { provider: "anthropic", label: "Claude Opus 5.5", supports_temperature: false, supports_effort: true }
        }
      end
      let(:data) do
        { content: "Test prompt", system_message: "System", temperature: 0.7, max_tokens: 1000, effort: "high", parameters_used: {} }
      end

      before { allow(PromptEngine.config).to receive(:models).and_return(models) }

      context "with a model that takes effort and rejects temperature" do
        let(:rendered_prompt) { described_class.new(prompt, data.merge(model: "claude-opus-5-5")) }

        it "sends effort as output_config and leaves temperature out" do
          params = rendered_prompt.to_ruby_llm_params

          expect(params).to include(output_config: { effort: "high" }, max_tokens: 1000)
          expect(params).not_to have_key(:temperature)
        end

        it "leaves an overridden temperature out too" do
          rendered = described_class.new(prompt, data.merge(model: "claude-opus-5-5"), { temperature: 0.2 })

          expect(rendered.to_ruby_llm_params).not_to have_key(:temperature)
        end

        it "uses an overridden effort" do
          rendered = described_class.new(prompt, data.merge(model: "claude-opus-5-5"), { effort: "low" })

          expect(rendered.to_ruby_llm_params[:output_config]).to eq(effort: "low")
        end
      end

      context "with a model that takes temperature but not effort" do
        let(:rendered_prompt) { described_class.new(prompt, data.merge(model: "gpt-4o")) }

        it "sends temperature and leaves effort out" do
          params = rendered_prompt.to_ruby_llm_params

          expect(params).to include(temperature: 0.7)
          expect(params).not_to have_key(:output_config)
        end
      end

      context "with a model outside the catalog" do
        let(:rendered_prompt) { described_class.new(prompt, data.merge(model: "some-model")) }

        it "sends temperature and leaves effort out" do
          params = rendered_prompt.to_ruby_llm_params

          expect(params).to include(temperature: 0.7)
          expect(params).not_to have_key(:output_config)
        end
      end
    end

    describe "#execute_with" do
      let(:test_rendered_data) do
        {
          content: "Test prompt",
          system_message: "Test system",
          model: "gpt-4o",
          temperature: 0.7,
          max_tokens: 1000,
          parameters_used: {},
          version_number: 1
        }
      end

      let(:rendered_prompt) { described_class.new(prompt, test_rendered_data) }

      context "with OpenAI client" do
        let(:openai_client) do
          client_class = double("Class", name: "OpenAI::Client")
          double("OpenAI::Client", class: client_class)
        end

        it "detects OpenAI client and calls chat with parameters key" do
          expected_params = {
            model: "gpt-4o",
            messages: [
              { role: "system", content: "Test system" },
              { role: "user", content: "Test prompt" }
            ],
            temperature: 0.7,
            max_completion_tokens: 1000
          }

          expect(openai_client).to receive(:chat).with(parameters: expected_params)
          rendered_prompt.execute_with(openai_client)
        end

        it "passes additional options to OpenAI parameters" do
          expect(openai_client).to receive(:chat).with(
            parameters: hash_including(stream: true, tools: [ "test" ])
          )

          rendered_prompt.execute_with(openai_client, stream: true, tools: [ "test" ])
        end
      end

      context "with RubyLLM" do
        let(:models) do
          { "claude-opus-5-5" => { provider: "anthropic", label: "Claude Opus 5.5", supports_temperature: false, supports_effort: true } }
        end
        let(:test_rendered_data) do
          { content: "Test prompt", system_message: "Test system", model: "claude-opus-5-5", temperature: 0.7, max_tokens: 1000, effort: "high", parameters_used: {} }
        end
        let(:context) { RubyLLM.context { |config| config.anthropic_api_key = "test-key" } }

        before do
          allow(PromptEngine.config).to receive(:models).and_return(models)
          body = {
            id: "msg_1", type: "message", role: "assistant", model: "claude-opus-5-5",
            content: [ { type: "text", text: "Hello" } ], stop_reason: "end_turn",
            usage: { input_tokens: 3, output_tokens: 1 }
          }
          stub_request(:post, "https://api.anthropic.com/v1/messages")
            .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
        end

        it "asks a model outside ruby_llm's registry and returns the message" do
          expect(rendered_prompt.execute_with(context).content).to eq("Hello")
        end

        it "sends the system message, settings and content" do
          rendered_prompt.execute_with(context)

          expect(WebMock).to have_requested(:post, "https://api.anthropic.com/v1/messages").with { |request|
            body = JSON.parse(request.body)
            body["system"].to_s.include?("Test system") &&
              body["max_tokens"] == 1000 &&
              body["output_config"] == { "effort" => "high" } &&
              !body.key?("temperature") &&
              body["messages"].last["content"].to_s.include?("Test prompt")
          }
        end

        it "rejects a ruby_llm provider object" do
          provider = RubyLLM::Providers::OpenAI.new(RubyLLM.context { |config| config.openai_api_key = "test-key" }.config)

          expect { rendered_prompt.execute_with(provider) }
            .to raise_error(ArgumentError, "Pass RubyLLM or a RubyLLM::Context, not a ruby_llm provider")
        end

        it "accepts the RubyLLM module itself" do
          allow(RubyLLM.config).to receive(:anthropic_api_key).and_return("test-key")

          expect(rendered_prompt.execute_with(RubyLLM).content).to eq("Hello")
        end
      end

      context "with unknown client" do
        it "raises ArgumentError for an unrecognized client, Anthropic's SDK included" do
          [ "RandomAPI::Client", "Anthropic::Client" ].each do |class_name|
            client = double(class_name, class: double("Class", name: class_name))

            expect {
              rendered_prompt.execute_with(client)
            }.to raise_error(ArgumentError, "Unknown client type: #{class_name}")
          end
        end
      end
    end
  end
end
