require "rails_helper"

RSpec.describe "PromptEngine::EvalSets Comparison", type: :request do
  include PromptEngine::Engine.routes.url_helpers

  let(:prompt) { create(:prompt) }
  let(:eval_set) { create(:eval_set, prompt: prompt) }
  let(:prompt_version1) { prompt.versions.first }
  let(:prompt_version2) { create(:prompt_version, prompt: prompt) }

  let!(:run1) do
    create(:eval_run, :completed,
      eval_set: eval_set,
      prompt_version: prompt_version1,
      total_count: 10,
      passed_count: 8,
      failed_count: 2,
      created_at: 2.hours.ago)
  end

  let!(:run2) do
    create(:eval_run, :completed,
      eval_set: eval_set,
      prompt_version: prompt_version2,
      total_count: 10,
      passed_count: 9,
      failed_count: 1,
      created_at: 1.hour.ago)
  end

  # Create test cases with results for comparison
  let!(:test_case1) { create(:test_case, eval_set: eval_set, description: "Test case 1") }
  let!(:test_case2) { create(:test_case, eval_set: eval_set, description: "Test case 2") }
  let!(:test_case3) { create(:test_case, eval_set: eval_set, description: "Test case 3") }

  before do
    # Create results for run1
    create(:eval_result, eval_run: run1, test_case: test_case1, passed: true)
    create(:eval_result, eval_run: run1, test_case: test_case2, passed: false)
    create(:eval_result, eval_run: run1, test_case: test_case3, passed: true)

    # Create results for run2
    create(:eval_result, eval_run: run2, test_case: test_case1, passed: true)
    create(:eval_result, eval_run: run2, test_case: test_case2, passed: true) # This one improved
    create(:eval_result, eval_run: run2, test_case: test_case3, passed: false) # This one regressed
  end

  describe "GET /prompt_engine/prompts/:prompt_id/eval_sets/:id/compare" do
    context "with valid run_ids" do
      it "displays comparison view successfully" do
        get compare_prompt_eval_set_path(prompt, eval_set, run_ids: [ run1.id, run2.id ])

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Compare Evaluation Runs")
        expect(response.body).to include("v#{prompt_version1.version_number}")
        expect(response.body).to include("v#{prompt_version2.version_number}")
      end

      it "shows summary statistics" do
        get compare_prompt_eval_set_path(prompt, eval_set, run_ids: [ run1.id, run2.id ])

        # Run 1 stats
        expect(response.body).to include("80.0%") # Success rate for run1
        expect(response.body).to include("8 / 10") # Passed count for run1

        # Run 2 stats
        expect(response.body).to include("90.0%") # Success rate for run2
        expect(response.body).to include("9 / 10") # Passed count for run2
      end

      it "shows improvements and regressions" do
        get compare_prompt_eval_set_path(prompt, eval_set, run_ids: [ run1.id, run2.id ])

        # Checking for improvement indicator (10% improvement from 80% to 90%)
        expect(response.body).to include("+10.0%")
        expect(response.body).to include("text-success") # CSS class for improved results
      end

      it "shows individual test case comparisons" do
        get compare_prompt_eval_set_path(prompt, eval_set, run_ids: [ run1.id, run2.id ])

        # The comparison view mentions test results are in OpenAI reports
        expect(response.body).to include("Individual test case results")
        expect(response.body).to include("OpenAI evaluation reports")
      end
    end

    context "with incomplete runs" do
      let!(:pending_run) do
        create(:eval_run, eval_set: eval_set, prompt_version: prompt_version1, status: :pending)
      end

      it "shows error for non-completed runs" do
        get compare_prompt_eval_set_path(prompt, eval_set, run_ids: [ run1.id, pending_run.id ])

        expect(response).to redirect_to(prompt_eval_set_path(prompt, eval_set))
        expect(flash[:alert]).to include("Both evaluation runs must be completed")
      end
    end

    context "with missing run_ids" do
      it "redirects with error when no run_ids provided" do
        get compare_prompt_eval_set_path(prompt, eval_set)

        expect(response).to redirect_to(prompt_eval_set_path(prompt, eval_set))
        expect(flash[:alert]).to include("select exactly two evaluation runs")
      end

      it "redirects with error when only one run_id provided" do
        get compare_prompt_eval_set_path(prompt, eval_set, run_ids: [ run1.id ])

        expect(response).to redirect_to(prompt_eval_set_path(prompt, eval_set))
        expect(flash[:alert]).to include("select exactly two evaluation runs")
      end

      it "redirects with error when more than two run_ids provided" do
        run3 = create(:eval_run, :completed, eval_set: eval_set, prompt_version: prompt_version1)
        get compare_prompt_eval_set_path(prompt, eval_set, run_ids: [ run1.id, run2.id, run3.id ])

        expect(response).to redirect_to(prompt_eval_set_path(prompt, eval_set))
        expect(flash[:alert]).to include("select exactly two evaluation runs")
      end
    end

    context "with invalid run_ids" do
      it "handles non-existent run" do
        get compare_prompt_eval_set_path(prompt, eval_set, run_ids: [ run1.id, 999999 ])

        expect(response).to redirect_to(prompt_eval_set_path(prompt, eval_set))
        expect(flash[:alert]).to include("One or both evaluation runs could not be found")
      end

      it "handles run from different eval_set" do
        other_eval_set = create(:eval_set, prompt: prompt)
        other_run = create(:eval_run, :completed, eval_set: other_eval_set, prompt_version: prompt_version1)

        get compare_prompt_eval_set_path(prompt, eval_set, run_ids: [ run1.id, other_run.id ])

        expect(response).to redirect_to(prompt_eval_set_path(prompt, eval_set))
        expect(flash[:alert]).to include("One or both evaluation runs could not be found")
      end
    end

    context "with no results data" do
      let!(:run_without_results1) do
        create(:eval_run, :completed,
          eval_set: eval_set,
          prompt_version: prompt_version1,
          total_count: 5,
          passed_count: 3,
          failed_count: 2)
      end

      let!(:run_without_results2) do
        create(:eval_run, :completed,
          eval_set: eval_set,
          prompt_version: prompt_version2,
          total_count: 5,
          passed_count: 4,
          failed_count: 1)
      end

      it "shows comparison based on aggregate counts" do
        get compare_prompt_eval_set_path(prompt, eval_set, run_ids: [ run_without_results1.id, run_without_results2.id ])

        expect(response).to have_http_status(:success)
        expect(response.body).to include("60.0%") # 3/5 for run1
        expect(response.body).to include("80.0%") # 4/5 for run2
        # Check that the comparison view still shows performance metrics
        expect(response.body).to include("Performance Comparison")
      end
    end
  end
end
