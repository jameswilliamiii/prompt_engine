module PromptEngine
  class PromptsController < ApplicationController
    before_action :set_prompt, only: [ :show, :edit, :update, :destroy ]

    def index
      @prompts = PromptEngine::Prompt.by_name
    end

    def show
      # Get recent test runs for this prompt across all versions
      @recent_test_runs = PromptEngine::PlaygroundRunResult
        .joins(:prompt_version)
        .where(prompt_engine_prompt_versions: { prompt_id: @prompt.id })
        .recent
        .limit(5)
        .includes(:prompt_version)

      # Get evaluation data for this prompt
      # @eval_sets = @prompt.eval_sets.includes(:test_cases, :eval_runs)
      # @recent_eval_runs = PromptEngine::EvalRun
      #   .joins(:eval_set)
      #   .where(prompt_engine_eval_sets: { prompt_id: @prompt.id })
      #   .order(created_at: :desc)
      #   .limit(5)
      #   .includes(:eval_set, :prompt_version)
    end

    def new
      @prompt = PromptEngine::Prompt.new
    end

    def create
      @prompt = PromptEngine::Prompt.new(prompt_params)

      if @prompt.save
        redirect_to prompt_path(@prompt), notice: "Prompt was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      # Determine if the new version should be active
      make_active = params[:commit] == "save_active"

      # Set the activation preference before updating
      @prompt.set_next_version_active(make_active)

      if @prompt.update(prompt_params)
        action_message = make_active ? "updated and made active" : "updated (saved as inactive version)"
        redirect_to prompt_path(@prompt), notice: "Prompt was successfully #{action_message}."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @prompt.destroy
      redirect_to prompts_path, notice: "Prompt was successfully deleted."
    end

    private

    def set_prompt
      @prompt = PromptEngine::Prompt.find(params[:id])
    end

    def prompt_params
      params.require(:prompt).permit(:name, :slug, :description, :content, :system_message, :model, :temperature, :max_tokens, :status, :json_mode,
        parameters_attributes: [ :id, :name, :description, :parameter_type, :required, :default_value, :_destroy ])
    end
  end
end
