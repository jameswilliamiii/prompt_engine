module PromptEngine
  class EvaluationsController < ApplicationController
    layout "prompt_engine/admin"

    def index
      @prompts_with_eval_sets = Prompt.joins(:eval_sets)
        .includes(eval_sets: [:eval_runs])
        .distinct
        .order(:name)

      # Calculate overall statistics
      @total_eval_sets = EvalSet.count
      @total_eval_runs = EvalRun.count
      @total_test_cases = TestCase.count

      # Get recent evaluation activity
      @recent_runs = EvalRun.includes(eval_set: :prompt, prompt_version: :prompt)
        .order(created_at: :desc)
        .limit(10)

      # Calculate overall pass rate
      completed_runs = EvalRun.where(status: "completed")
      if completed_runs.any?
        total_passed = completed_runs.sum(:passed_count)
        total_tests = completed_runs.sum(:total_count)
        @overall_pass_rate = (total_tests > 0) ? (total_passed.to_f / total_tests * 100).round(2) : 0
      else
        @overall_pass_rate = 0
      end
    end
  end
end
