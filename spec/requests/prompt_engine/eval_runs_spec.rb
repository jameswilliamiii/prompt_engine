require "rails_helper"

module PromptEngine
  RSpec.describe "EvalRuns", type: :request do
    let(:prompt) { create(:prompt) }
    let(:prompt_version) { create(:prompt_version, prompt: prompt) }
    let(:eval_set) { create(:eval_set, prompt: prompt) }
    let(:eval_run) { create(:eval_run, eval_set: eval_set, prompt_version: prompt_version) }

    describe "GET /prompt_engine/prompts/:prompt_id/eval_runs/:id" do
      context "with a pending eval run" do
        let(:pending_run) { create(:eval_run, eval_set: eval_set, prompt_version: prompt_version, status: "pending") }

        it "returns a success response" do
          get prompt_engine.prompt_eval_run_path(prompt, pending_run)
          expect(response).to be_successful
        end

        it "displays the eval run status" do
          get prompt_engine.prompt_eval_run_path(prompt, pending_run)
          expect(response.body).to include("Pending")
        end
      end

      context "with a running eval run" do
        let(:running_run) { create(:eval_run, :running, eval_set: eval_set, prompt_version: prompt_version) }

        it "returns a success response" do
          get prompt_engine.prompt_eval_run_path(prompt, running_run)
          expect(response).to be_successful
        end

        it "displays the running status" do
          get prompt_engine.prompt_eval_run_path(prompt, running_run)
          expect(response.body).to include("Running")
        end

        it "includes auto-refresh script" do
          get prompt_engine.prompt_eval_run_path(prompt, running_run)
          expect(response.body).to include("setTimeout")
          expect(response.body).to include("location.reload()")
        end
      end

      context "with a completed eval run" do
        let(:completed_run) { create(:eval_run, :completed, eval_set: eval_set, prompt_version: prompt_version) }

        it "returns a success response" do
          get prompt_engine.prompt_eval_run_path(prompt, completed_run)
          expect(response).to be_successful
        end

        it "displays the completion summary" do
          get prompt_engine.prompt_eval_run_path(prompt, completed_run)
          expect(response.body).to include("Completed")
          expect(response.body).to include(completed_run.passed_count.to_s)
          expect(response.body).to include(completed_run.failed_count.to_s)
        end

        it "calculates and displays success rate" do
          get prompt_engine.prompt_eval_run_path(prompt, completed_run)
          success_rate = (completed_run.passed_count.to_f / completed_run.total_count * 100).round(1)
          expect(response.body).to include("#{success_rate}%")
        end
      end

      context "with a failed eval run" do
        let(:failed_run) { create(:eval_run, :failed, eval_set: eval_set, prompt_version: prompt_version) }

        it "returns a success response" do
          get prompt_engine.prompt_eval_run_path(prompt, failed_run)
          expect(response).to be_successful
        end

        it "displays the error message" do
          get prompt_engine.prompt_eval_run_path(prompt, failed_run)
          expect(response.body).to include("Failed")
          expect(response.body).to include(failed_run.error_message)
        end
      end

      context "with OpenAI integration data" do
        let(:openai_run) do
          create(:eval_run,
            :completed,
            eval_set: eval_set,
            prompt_version: prompt_version,
            openai_run_id: "run_123",
            report_url: "https://platform.openai.com/evals/run_123")
        end

        it "displays link to OpenAI report when available" do
          get prompt_engine.prompt_eval_run_path(prompt, openai_run)
          expect(response.body).to include("View OpenAI Report")
          expect(response.body).to include(openai_run.report_url)
        end
      end

      it "displays the prompt version number" do
        get prompt_engine.prompt_eval_run_path(prompt, eval_run)
        expect(response.body).to include("v#{prompt_version.version_number}")
      end

      it "includes a back link to the eval set" do
        get prompt_engine.prompt_eval_run_path(prompt, eval_run)
        expect(response.body).to include(prompt_engine.prompt_eval_set_path(prompt, eval_set))
      end
    end
  end
end
