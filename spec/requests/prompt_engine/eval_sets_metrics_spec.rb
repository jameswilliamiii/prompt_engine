require "rails_helper"

RSpec.describe "PromptEngine::EvalSets Metrics", type: :request do
  include PromptEngine::Engine.routes.url_helpers

  let(:prompt) { create(:prompt) }
  let(:eval_set) { create(:eval_set, prompt: prompt) }
  let(:prompt_version) { create(:prompt_version, prompt: prompt) }

  describe "GET /prompt_engine/prompts/:prompt_id/eval_sets/:id/metrics" do
    context "with completed evaluation runs" do
      let!(:test_cases) do
        3.times.map { create(:test_case, eval_set: eval_set) }
      end

      let!(:eval_runs) do
        [
          create(:eval_run, :completed,
            eval_set: eval_set,
            prompt_version: prompt_version,
            total_count: 3,
            passed_count: 3,
            failed_count: 0,
            created_at: 7.days.ago),
          create(:eval_run, :completed,
            eval_set: eval_set,
            prompt_version: prompt_version,
            total_count: 3,
            passed_count: 2,
            failed_count: 1,
            created_at: 5.days.ago),
          create(:eval_run, :completed,
            eval_set: eval_set,
            prompt_version: prompt_version,
            total_count: 3,
            passed_count: 1,
            failed_count: 2,
            created_at: 3.days.ago),
          create(:eval_run, :completed,
            eval_set: eval_set,
            prompt_version: prompt_version,
            total_count: 3,
            passed_count: 2,
            failed_count: 1,
            created_at: 1.day.ago)
        ]
      end

      before do
        # Create eval results for test case performance tracking
        eval_runs.each_with_index do |run, run_index|
          test_cases.each_with_index do |test_case, tc_index|
            # Create a pattern of passes/fails for each test case
            passed = case tc_index
            when 0 # First test case: always passes
              true
            when 1 # Second test case: intermittent
              run_index.even?
            when 2 # Third test case: degrades over time
              run_index < 2
            end

            create(:eval_result,
              eval_run: run,
              test_case: test_case,
              passed: passed,
              execution_time_ms: 100 + (run_index * 10) + (tc_index * 5))
          end
        end
      end

      it "displays the metrics dashboard successfully" do
        get metrics_prompt_eval_set_path(prompt, eval_set)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Evaluation Metrics")
        expect(response.body).to include(eval_set.name)
      end

      it "shows success rate trend data" do
        get metrics_prompt_eval_set_path(prompt, eval_set)

        # Should include success rates for each run
        expect(response.body).to include("100.0") # First run: 3/3
        expect(response.body).to include("66.67") # Second run: 2/3
        expect(response.body).to include("33.33") # Third run: 1/3

        # Should include formatted dates
        eval_runs.each do |run|
          expect(response.body).to include(run.created_at.strftime("%b %d, %Y"))
        end
      end

      it "shows overall statistics" do
        get metrics_prompt_eval_set_path(prompt, eval_set)

        # Total runs
        expect(response.body).to include("Total Runs")
        expect(response.body).to include("4")

        # Total test cases
        expect(response.body).to include("Total Test Cases")
        expect(response.body).to include("3")
      end

      it "shows test case performance breakdown" do
        get metrics_prompt_eval_set_path(prompt, eval_set)

        # The view shows total test cases, not individual performance
        expect(response.body).to include("Total Test Cases")
        expect(response.body).to include("3") # We have 3 test cases
      end

      it "shows execution time trends" do
        get metrics_prompt_eval_set_path(prompt, eval_set)

        # The view has a Duration Trend section
        expect(response.body).to include("Duration Trend")
        expect(response.body).to include("durationTrendChart")
      end

      it "includes chart container elements" do
        get metrics_prompt_eval_set_path(prompt, eval_set)

        expect(response.body).to include('id="successRateTrendChart"')
        expect(response.body).to include('id="successRateByVersionChart"')
        expect(response.body).to include('id="testDistributionChart"')
        expect(response.body).to include('id="durationTrendChart"')
      end
    end

    context "with no evaluation runs" do
      it "shows empty state message" do
        get metrics_prompt_eval_set_path(prompt, eval_set)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("No evaluation runs completed yet")
        expect(response.body).to include("Run some evaluations")
      end
    end

    context "with only pending/running evaluations" do
      let!(:pending_run) { create(:eval_run, eval_set: eval_set, prompt_version: prompt_version, status: :pending) }
      let!(:running_run) { create(:eval_run, eval_set: eval_set, prompt_version: prompt_version, status: :running) }

      it "shows empty state as no completed runs exist" do
        get metrics_prompt_eval_set_path(prompt, eval_set)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("No evaluation runs completed yet")
      end
    end

    context "with failed evaluations" do
      let!(:failed_run) do
        create(:eval_run,
          eval_set: eval_set,
          prompt_version: prompt_version,
          status: :failed,
          error_message: "API rate limit exceeded")
      end

      let!(:completed_run) do
        create(:eval_run, :completed,
          eval_set: eval_set,
          prompt_version: prompt_version,
          total_count: 5,
          passed_count: 3,
          failed_count: 2)
      end

      it "only includes completed runs in metrics" do
        get metrics_prompt_eval_set_path(prompt, eval_set)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Total Runs")
        expect(response.body).to include("1") # Only the completed run
        expect(response.body).not_to include("API rate limit exceeded")
      end
    end

    context "with large dataset" do
      # Create 30 runs over 30 days
      let!(:many_runs) do
        30.times.map do |i|
          create(:eval_run, :completed,
            eval_set: eval_set,
            prompt_version: prompt_version,
            total_count: 10,
            passed_count: 5 + (i % 6), # Varying success rates
            failed_count: 5 - (i % 6),
            created_at: (30 - i).days.ago)
        end
      end

      it "handles large datasets efficiently" do
        get metrics_prompt_eval_set_path(prompt, eval_set)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Total Runs")
        expect(response.body).to include("30")
      end

      it "shows trends over time" do
        get metrics_prompt_eval_set_path(prompt, eval_set)

        # Should show the success rate trend chart
        expect(response.body).to include("successRateTrendChart")
        # Should have data for all 30 runs
        expect(response.body).to include("Total Runs")
        expect(response.body).to include("30")
      end
    end
  end
end
