require "rails_helper"

module PromptEngine
  RSpec.describe "PlaygroundRunResults", type: :request do
    include Engine.routes.url_helpers

    let(:prompt) { create(:prompt) }
    let(:prompt_version) { prompt.current_version }
    let!(:playground_run_result) { create(:playground_run_result, prompt_version: prompt_version) }

    describe "GET /prompt_engine/playground_run_results/:id" do
      it "returns a successful response" do
        get playground_run_result_path(playground_run_result)
        expect(response).to be_successful
      end

      it "displays the run details" do
        get playground_run_result_path(playground_run_result)
        expect(response.body).to include("Test Run Details")
        expect(response.body).to include(playground_run_result.provider)
        expect(response.body).to include(playground_run_result.model)
      end
    end

    describe "GET /prompt_engine/prompts/:prompt_id/playground_run_results" do
      it "returns a successful response" do
        get prompt_playground_run_results_path(prompt)
        expect(response).to be_successful
      end

      it "displays test runs for the prompt" do
        get prompt_playground_run_results_path(prompt)
        expect(response.body).to include("Test Run Results")
        expect(response.body).to include(prompt.name)
        expect(response.body).to include(playground_run_result.provider)
      end

      context "when no test runs exist" do
        before { PlaygroundRunResult.destroy_all }

        it "shows an empty state message" do
          get prompt_playground_run_results_path(prompt)
          expect(response.body).to include("No test runs yet")
        end
      end
    end

    describe "GET /prompt_engine/prompts/:prompt_id/versions/:version_id/playground_run_results" do
      it "returns a successful response" do
        get prompt_version_playground_run_results_path(prompt, prompt_version)
        expect(response).to be_successful
      end

      it "displays test runs for the specific version" do
        get prompt_version_playground_run_results_path(prompt, prompt_version)
        expect(response.body).to include("Test Run Results")
        expect(response.body).to include(prompt.name)
        expect(response.body).to include(playground_run_result.provider)
      end
    end
  end
end
