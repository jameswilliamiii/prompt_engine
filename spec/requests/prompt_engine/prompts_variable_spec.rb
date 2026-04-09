require "rails_helper"

module PromptEngine
  RSpec.describe "Prompts with Variables", type: :request do
    describe "POST /prompt_engine/prompts" do
      context "when creating a prompt with variables" do
        it "creates a prompt and auto-detects parameters" do
          prompt_params = {
            name: "User Welcome",
            content: "Hello {{user_name}}, welcome to {{company}}! Your ID is {{user_id}}.",
            status: "draft"
          }

          expect {
            post "/prompt_engine/prompts", params: { prompt: prompt_params }
          }.to change(Prompt, :count).by(1)

          prompt = Prompt.last
          expect(prompt.parameters.count).to eq(3)
          expect(prompt.parameters.pluck(:name)).to contain_exactly("user_name", "company", "user_id")

          # Check type inference
          user_id_param = prompt.parameters.find_by(name: "user_id")
          expect(user_id_param.parameter_type).to eq("integer")
        end

        it "handles prompts with complex variables" do
          prompt_params = {
            name: "Order Summary",
            content: "Order #\{{order_id}} for {{customer_name}}. Total: ${{total_price}}, Created: {{created_at}}",
            status: "draft"
          }

          post "/prompt_engine/prompts", params: { prompt: prompt_params }

          prompt = Prompt.last
          expect(prompt).to be_persisted

          # Verify parameter types were inferred correctly
          params_by_name = prompt.parameters.index_by(&:name)
          expect(params_by_name["order_id"].parameter_type).to eq("integer")
          expect(params_by_name["customer_name"].parameter_type).to eq("string")
          expect(params_by_name["total_price"].parameter_type).to eq("decimal")
          expect(params_by_name["created_at"].parameter_type).to eq("datetime")
        end

        it "creates initial version with content" do
          prompt_params = {
            name: "Test Prompt",
            content: "Hello {{name}}!",
            status: "draft"
          }

          post "/prompt_engine/prompts", params: { prompt: prompt_params }

          prompt = Prompt.last
          expect(prompt.versions.count).to eq(1)
          expect(prompt.current_version.content).to eq("Hello {{name}}!")
        end
      end

      context "when updating a prompt's variables" do
        let(:prompt) { create(:prompt, content: "Hello {{name}}!") }

        it "syncs parameters when content changes" do
          patch "/prompt_engine/prompts/#{prompt.id}", params: {
            prompt: { content: "Hello {{first_name}} {{last_name}}!" }
          }

          prompt.reload
          expect(prompt.parameters.pluck(:name)).to contain_exactly("first_name", "last_name")
        end
      end

      context "when editing a saved prompt with existing parameters" do
        let(:prompt) { create(:prompt, content: "{{email}} and {{user_name}}") }

        before { prompt.reload }

        it "updates without validation errors when parameters are submitted with their ids" do
          email_param = prompt.parameters.find_by(name: "email")
          user_name_param = prompt.parameters.find_by(name: "user_name")

          patch "/prompt_engine/prompts/#{prompt.id}", params: {
            prompt: {
              content: prompt.content,
              parameters_attributes: {
                "0" => { id: email_param.id, name: "email", parameter_type: "string", required: "1" },
                "1" => { id: user_name_param.id, name: "user_name", parameter_type: "string", required: "1" }
              }
            }
          }

          expect(response).to redirect_to(prompt_engine.prompt_path(prompt))
        end

        it "does not raise uniqueness errors when variables appear in different order than DB storage" do
          email_param = prompt.parameters.find_by(name: "email")
          user_name_param = prompt.parameters.find_by(name: "user_name")

          # Simulate the bug: JS detects in content order (user_name, email),
          # but parameters_attributes indices match that content order with correct ids
          patch "/prompt_engine/prompts/#{prompt.id}", params: {
            prompt: {
              content: "{{user_name}} and {{email}}",
              parameters_attributes: {
                "0" => { id: user_name_param.id, name: "user_name", parameter_type: "string", required: "1" },
                "1" => { id: email_param.id, name: "email", parameter_type: "string", required: "1" }
              }
            }
          }

          expect(response).to redirect_to(prompt_engine.prompt_path(prompt))
        end

        it "updates non-content fields without raising parameter validation errors" do
          email_param = prompt.parameters.find_by(name: "email")
          user_name_param = prompt.parameters.find_by(name: "user_name")

          patch "/prompt_engine/prompts/#{prompt.id}", params: {
            prompt: {
              description: "Updated description",
              temperature: 0.9,
              parameters_attributes: {
                "0" => { id: email_param.id, name: "email", parameter_type: "string", required: "1" },
                "1" => { id: user_name_param.id, name: "user_name", parameter_type: "string", required: "1" }
              }
            }
          }

          expect(response).to redirect_to(prompt_engine.prompt_path(prompt))
          prompt.reload
          expect(prompt.description).to eq("Updated description")
          expect(prompt.temperature).to eq(0.9)
        end
      end
    end
  end
end
