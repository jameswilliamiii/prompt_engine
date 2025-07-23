module ActivePrompt
  class ParametersController < ApplicationController
    layout "active_prompt/admin"
    
    before_action :set_prompt
    before_action :set_parameter, only: [:edit, :update, :destroy]
    
    def index
      @parameters = @prompt.parameters.ordered
      @detected_variables = @prompt.detect_variables
    end
    
    def new
      @parameter = @prompt.parameters.build
      @parameter.name = params[:name] if params[:name].present?
      @parameter.parameter_type = params[:type] || 'string'
    end
    
    def create
      @parameter = @prompt.parameters.build(parameter_params)
      
      if @parameter.save
        redirect_to prompt_parameters_path(@prompt), 
                    notice: 'Parameter was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    def edit
    end
    
    def update
      if @parameter.update(parameter_params)
        redirect_to prompt_parameters_path(@prompt), 
                    notice: 'Parameter was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end
    
    def destroy
      @parameter.destroy!
      redirect_to prompt_parameters_path(@prompt), 
                  notice: 'Parameter was successfully removed.'
    end
    
    def sync
      @prompt.sync_parameters!
      redirect_to prompt_parameters_path(@prompt), 
                  notice: 'Parameters synced with prompt content.'
    end
    
    private
    
    def set_prompt
      @prompt = Prompt.find(params[:prompt_id])
    end
    
    def set_parameter
      @parameter = @prompt.parameters.find(params[:id])
    end
    
    def parameter_params
      params.require(:parameter).permit(
        :name, :description, :parameter_type, :required, 
        :default_value, :example_value, :position,
        validation_rules: {}
      )
    end
  end
end