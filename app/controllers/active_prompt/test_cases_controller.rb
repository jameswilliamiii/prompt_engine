module ActivePrompt
  class TestCasesController < ApplicationController
    before_action :set_prompt
    before_action :set_eval_set
    before_action :set_test_case, only: [:edit, :update, :destroy]
    
    def new
      @test_case = @eval_set.test_cases.build
      # Pre-populate with prompt's parameters
      @test_case.input_variables = @prompt.parameters.each_with_object({}) do |param, hash|
        hash[param.name] = param.default_value
      end
    end
    
    def create
      @test_case = @eval_set.test_cases.build(test_case_params)
      
      if @test_case.save
        redirect_to prompt_eval_set_path(@prompt, @eval_set)
      else
        render :new
      end
    end
    
    def edit
    end
    
    def update
      if @test_case.update(test_case_params)
        redirect_to prompt_eval_set_path(@prompt, @eval_set)
      else
        render :edit
      end
    end
    
    def destroy
      @test_case.destroy
      redirect_to prompt_eval_set_path(@prompt, @eval_set)
    end
    
    private
    
    def set_prompt
      @prompt = Prompt.find(params[:prompt_id])
    end
    
    def set_eval_set
      @eval_set = @prompt.eval_sets.find(params[:eval_set_id])
    end
    
    def set_test_case
      @test_case = @eval_set.test_cases.find(params[:id])
    end
    
    def test_case_params
      params.require(:test_case).permit(:description, :expected_output, input_variables: {})
    end
  end
end