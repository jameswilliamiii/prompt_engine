require "rails_helper"

module PromptEngine
  RSpec.describe "Prompts", type: :request do
    let(:valid_attributes) do
      {
        name: "Test Prompt",
        description: "A test prompt",
        content: "Generate a {{type}} response",
        system_message: "You are a helpful assistant",
        model: "gpt-4",
        temperature: 0.7,
        max_tokens: 1000,
        status: "draft"
      }
    end

    let(:invalid_attributes) do
      {
        name: "",
        content: "",
        description: "Invalid prompt without required fields"
      }
    end

    describe "GET /prompt_engine/prompts" do
      let!(:prompt1) { create(:prompt, name: "First Prompt") }
      let!(:prompt2) { create(:prompt, name: "Second Prompt") }

      it "returns a success response" do
        get prompt_engine.prompts_path
        expect(response).to be_successful
      end

      it "displays all prompts" do
        get prompt_engine.prompts_path
        expect(response.body).to include(prompt1.name)
        expect(response.body).to include(prompt2.name)
      end
    end

    describe "GET /prompt_engine/prompts/:id" do
      let(:prompt) { create(:prompt) }

      it "returns a success response" do
        get prompt_engine.prompt_path(prompt)
        expect(response).to be_successful
      end

      it "displays the prompt details" do
        get prompt_engine.prompt_path(prompt)
        expect(response.body).to include(prompt.name)
        expect(response.body).to include(prompt.description)
      end

      it "marks a stored setting the model doesn't take" do
        prompt.update!(model: "claude-opus-5-5", temperature: 0.7)

        get prompt_engine.prompt_path(prompt)

        expect(response.body).to include("0.7 (not sent to this model)")
        expect(response.body).to include("rendered.temperature    # => nil")
      end

      it "shows a usage example that passes variables as a hash" do
        get prompt_engine.prompt_path(prompt)

        code = CGI.unescapeHTML(response.body[/Usage Example.*?<code[^>]*>(.*?)<\/code>/m, 1])
        expect(code).to include("PromptEngine.render(\"#{prompt.slug}\", {\n  topic: \"value1\"\n})")
      end
    end

    describe "GET /prompt_engine/prompts/new" do
      it "returns a success response" do
        get prompt_engine.new_prompt_path
        expect(response).to be_successful
      end

      it "displays the new prompt form" do
        get prompt_engine.new_prompt_path
        expect(response.body).to include("New Prompt")
      end
    end

    describe "POST /prompt_engine/prompts" do
      context "with valid params" do
        it "creates a new Prompt" do
          expect {
            post prompt_engine.prompts_path, params: { prompt: valid_attributes }
          }.to change(PromptEngine::Prompt, :count).by(1)
        end

        it "redirects to the created prompt" do
          post prompt_engine.prompts_path, params: { prompt: valid_attributes }
          expect(response).to redirect_to(prompt_engine.prompt_path(PromptEngine::Prompt.last))
        end

        it "sets a success notice" do
          post prompt_engine.prompts_path, params: { prompt: valid_attributes }
          follow_redirect!
          expect(response.body).to include("Prompt was successfully created.")
        end
      end

      context "with invalid params" do
        it "does not create a new Prompt" do
          expect {
            post prompt_engine.prompts_path, params: { prompt: invalid_attributes }
          }.not_to change(PromptEngine::Prompt, :count)
        end

        it "returns unprocessable entity status" do
          post prompt_engine.prompts_path, params: { prompt: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "renders the new template with errors" do
          post prompt_engine.prompts_path, params: { prompt: invalid_attributes }
          expect(response.body).to include("error")
        end
      end
    end

    describe "GET /prompt_engine/prompts/:id/edit" do
      let(:prompt) { create(:prompt) }

      it "describes an unlisted model's capabilities from its family" do
        prompt.update!(model: "claude-opus-5")

        get prompt_engine.edit_prompt_path(prompt)

        option = Nokogiri::HTML(response.body).at_css('option[value="claude-opus-5"]')
        expect(option["data-supports-temperature"]).to eq("false")
        expect(option["data-supports-effort"]).to eq("true")
      end

      it "keeps a model missing from the catalog selected" do
        prompt.update!(model: "gpt-4-unlisted")

        get prompt_engine.edit_prompt_path(prompt)

        option = Nokogiri::HTML(response.body).at_css('option[value="gpt-4-unlisted"]')
        expect(option["selected"]).to eq("selected")
        expect(option.text).to eq("gpt-4-unlisted (not configured)")
      end

      it "returns a success response" do
        get prompt_engine.edit_prompt_path(prompt)
        expect(response).to be_successful
      end

      it "displays the edit form" do
        get prompt_engine.edit_prompt_path(prompt)
        expect(response.body).to include("Edit Prompt")
        expect(response.body).to include(prompt.name)
      end
    end

    describe "PATCH /prompt_engine/prompts/:id" do
      let(:prompt) { create(:prompt) }

      context "with valid params" do
        let(:new_attributes) do
          {
            name: "Updated Prompt Name",
            description: "Updated description",
            temperature: 0.9
          }
        end

        it "updates the requested prompt" do
          patch prompt_engine.prompt_path(prompt), params: { prompt: new_attributes }
          prompt.reload
          expect(prompt.name).to eq("Updated Prompt Name")
          expect(prompt.description).to eq("Updated description")
          expect(prompt.temperature).to eq(0.9)
        end

        it "saves effort" do
          patch prompt_engine.prompt_path(prompt), params: { prompt: { model: "claude-opus-5-5", effort: "high" } }

          expect(prompt.reload.effort).to eq("high")
        end

        it "redirects to the prompt" do
          patch prompt_engine.prompt_path(prompt), params: { prompt: new_attributes }
          expect(response).to redirect_to(prompt_engine.prompt_path(prompt))
        end

        it "sets a success notice" do
          patch prompt_engine.prompt_path(prompt), params: { prompt: new_attributes }
          follow_redirect!
          expect(response.body).to include("Prompt was successfully updated.")
        end
      end

      context "with invalid params" do
        it "does not update the prompt" do
          original_name = prompt.name
          patch prompt_engine.prompt_path(prompt), params: { prompt: invalid_attributes }
          prompt.reload
          expect(prompt.name).to eq(original_name)
        end

        it "returns unprocessable entity status" do
          patch prompt_engine.prompt_path(prompt), params: { prompt: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "renders the edit template with errors" do
          patch prompt_engine.prompt_path(prompt), params: { prompt: invalid_attributes }
          expect(response.body).to include("error")
        end
      end
    end

    describe "PUT /prompt_engine/prompts/:id" do
      let(:prompt) { create(:prompt) }

      context "with valid params" do
        let(:new_attributes) do
          {
            name: "Updated Prompt Name",
            description: "Updated description",
            temperature: 0.9
          }
        end

        it "updates the requested prompt" do
          put prompt_engine.prompt_path(prompt), params: { prompt: new_attributes }
          prompt.reload
          expect(prompt.name).to eq("Updated Prompt Name")
          expect(prompt.description).to eq("Updated description")
          expect(prompt.temperature).to eq(0.9)
        end

        it "redirects to the prompt" do
          put prompt_engine.prompt_path(prompt), params: { prompt: new_attributes }
          expect(response).to redirect_to(prompt_engine.prompt_path(prompt))
        end

        it "sets a success notice" do
          put prompt_engine.prompt_path(prompt), params: { prompt: new_attributes }
          follow_redirect!
          expect(response.body).to include("Prompt was successfully updated.")
        end
      end

      context "with invalid params" do
        it "does not update the prompt" do
          original_name = prompt.name
          put prompt_engine.prompt_path(prompt), params: { prompt: invalid_attributes }
          prompt.reload
          expect(prompt.name).to eq(original_name)
        end

        it "returns unprocessable entity status" do
          put prompt_engine.prompt_path(prompt), params: { prompt: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "renders the edit template with errors" do
          put prompt_engine.prompt_path(prompt), params: { prompt: invalid_attributes }
          expect(response.body).to include("error")
        end
      end
    end

    describe "DELETE /prompt_engine/prompts/:id" do
      let!(:prompt) { create(:prompt) }

      it "destroys the requested prompt" do
        expect {
          delete prompt_engine.prompt_path(prompt)
        }.to change(PromptEngine::Prompt, :count).by(-1)
      end

      it "redirects to the prompts list" do
        delete prompt_engine.prompt_path(prompt)
        expect(response).to redirect_to(prompt_engine.prompts_path)
      end

      it "sets a success notice" do
        delete prompt_engine.prompt_path(prompt)
        follow_redirect!
        expect(response.body).to include("Prompt was successfully deleted.")
      end
    end
  end
end
