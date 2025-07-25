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
        redirect_to prompt_eval_set_path(@prompt, @eval_set)
      else
        render :new
      end
    end
    
    def run
      # Create new eval run with current prompt version
      @eval_run = @eval_set.eval_runs.create!(
        prompt_version: @prompt.current_version
      )
      
      # Run evaluation synchronously for MVP
      EvaluationRunner.new(@eval_run).execute
      
      redirect_to prompt_eval_run_path(@prompt, @eval_run)
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