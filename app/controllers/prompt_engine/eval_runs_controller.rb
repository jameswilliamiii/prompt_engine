module PromptEngine
  class EvalRunsController < ApplicationController
    before_action :set_prompt
    before_action :set_eval_run

    def show
      # Note: Individual eval results are not fetched in MVP
      # Only aggregate counts from OpenAI are displayed
    end

    private

    def set_prompt
      @prompt = Prompt.find(params[:prompt_id])
    end

    def set_eval_run
      @eval_run = EvalRun.find(params[:id])
    end
  end
end
