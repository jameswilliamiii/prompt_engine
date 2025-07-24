module ActivePrompt
  class PromptsController < ApplicationController
    layout "active_prompt/admin"
      before_action :set_prompt, only: [ :show, :edit, :update, :destroy ]

      def index
        @prompts = ActivePrompt::Prompt.by_name
      end

      def show
        # Get recent test runs for this prompt across all versions
        @recent_test_runs = ActivePrompt::PlaygroundRunResult
          .joins(:prompt_version)
          .where(active_prompt_prompt_versions: { prompt_id: @prompt.id })
          .recent
          .limit(5)
          .includes(:prompt_version)
      end

      def new
        @prompt = ActivePrompt::Prompt.new
      end

      def create
        @prompt = ActivePrompt::Prompt.new(prompt_params)

        if @prompt.save
          redirect_to prompt_path(@prompt), notice: "Prompt was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @prompt.update(prompt_params)
          redirect_to prompt_path(@prompt), notice: "Prompt was successfully updated."
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
        @prompt = ActivePrompt::Prompt.find(params[:id])
      end

      def prompt_params
        params.require(:prompt).permit(:name, :description, :content, :system_message, :model, :temperature, :max_tokens, :status,
          parameters_attributes: [ :id, :name, :description, :parameter_type, :required, :default_value, :_destroy ])
      end
  end
end
