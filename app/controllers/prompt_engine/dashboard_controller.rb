module PromptEngine
  class DashboardController < ApplicationController
    layout "prompt_engine/admin"

    def index
      @recent_prompts = Prompt.includes(:parameters).order(updated_at: :desc).limit(5)
      @recent_test_runs = PlaygroundRunResult.includes(prompt_version: :prompt).order(created_at: :desc).limit(5)

      # Statistics
      @total_prompts = Prompt.count
      @prompt_engines = Prompt.active.count
      @total_test_runs = PlaygroundRunResult.count
      @total_tokens_used = PlaygroundRunResult.sum(:token_count) || 0

      # Evaluation statistics
      @total_eval_sets = EvalSet.count
      @total_eval_runs = EvalRun.count
      @recent_eval_runs = EvalRun.includes(eval_set: :prompt)
        .where(status: "completed")
        .order(created_at: :desc)
        .limit(5)
    end
  end
end
