module ActivePrompt
  class EvalSetsController < ApplicationController
    before_action :set_prompt
    before_action :set_eval_set, only: [:show, :edit, :update, :destroy, :run]
    
    def index
      @eval_sets = @prompt.eval_sets
    end
    
    def show
      @test_cases = @eval_set.test_cases
      @recent_runs = @eval_set.eval_runs.order(created_at: :desc).limit(5)
    end
    
    def new
      @eval_set = @prompt.eval_sets.build
    end
    
    def create
      @eval_set = @prompt.eval_sets.build(eval_set_params)
      
      if @eval_set.save
        redirect_to prompt_eval_set_path(@prompt, @eval_set), notice: "Evaluation set was successfully created."
      else
        flash.now[:alert] = "Please fix the errors below."
        render :new
      end
    end
    
    def edit
    end
    
    def update
      if @eval_set.update(eval_set_params)
        redirect_to prompt_eval_set_path(@prompt, @eval_set), notice: "Evaluation set was successfully updated."
      else
        flash.now[:alert] = "Please fix the errors below."
        render :edit
      end
    end
    
    def destroy
      @eval_set.destroy
      redirect_to prompt_eval_sets_path(@prompt), notice: "Evaluation set was successfully deleted."
    end
    
    def run
      # Create new eval run with current prompt version
      @eval_run = @eval_set.eval_runs.create!(
        prompt_version: @prompt.current_version
      )
      
      begin
        # Run evaluation synchronously for MVP
        EvaluationRunner.new(@eval_run).execute
        redirect_to prompt_eval_run_path(@prompt, @eval_run), notice: "Evaluation started successfully"
      rescue ActivePrompt::OpenAiEvalsClient::AuthenticationError => e
        @eval_run.update!(status: :failed, error_message: e.message)
        redirect_to prompt_eval_set_path(@prompt, @eval_set), alert: "Authentication failed: Please check your OpenAI API key configuration"
      rescue ActivePrompt::OpenAiEvalsClient::RateLimitError => e
        @eval_run.update!(status: :failed, error_message: e.message)
        redirect_to prompt_eval_set_path(@prompt, @eval_set), alert: "Rate limit exceeded: Please try again later"
      rescue ActivePrompt::OpenAiEvalsClient::APIError => e
        @eval_run.update!(status: :failed, error_message: e.message)
        redirect_to prompt_eval_set_path(@prompt, @eval_set), alert: "API error: #{e.message}"
      rescue StandardError => e
        @eval_run.update!(status: :failed, error_message: e.message)
        Rails.logger.error "Evaluation error: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        redirect_to prompt_eval_set_path(@prompt, @eval_set), alert: "Evaluation failed: #{e.message}"
      end
    end
    
    private
    
    def set_prompt
      @prompt = Prompt.find(params[:prompt_id])
    end
    
    def set_eval_set
      @eval_set = @prompt.eval_sets.find(params[:id])
    end
    
    def eval_set_params
      params.require(:eval_set).permit(:name, :description)
    end
  end
end