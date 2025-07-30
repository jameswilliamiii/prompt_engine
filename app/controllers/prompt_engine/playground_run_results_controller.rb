module PromptEngine
  class PlaygroundRunResultsController < ApplicationController
    before_action :set_playground_run_result, only: [ :show ]
    before_action :set_context, only: [ :index ]

    def index
      @playground_run_results = scope.recent.includes(prompt_version: :prompt)
    end

    def show
    end

    private

    def set_playground_run_result
      @playground_run_result = PlaygroundRunResult.find(params[:id])
    end

    def set_context
      if params[:prompt_id]
        @prompt = Prompt.find(params[:prompt_id])
      elsif params[:version_id]
        @prompt_version = PromptVersion.find(params[:version_id])
        @prompt = @prompt_version.prompt
      end
    end

    def scope
      if params[:prompt_id]
        # Get all playground run results for all versions of this prompt
        PlaygroundRunResult.joins(:prompt_version).where(prompt_engine_prompt_versions: { prompt_id: params[:prompt_id] })
      elsif params[:version_id]
        # Get playground run results for a specific version
        PromptVersion.find(params[:version_id]).playground_run_results
      else
        PlaygroundRunResult.all
      end
    end
  end
end
