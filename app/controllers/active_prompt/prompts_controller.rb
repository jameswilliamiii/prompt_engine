module ActivePrompt
  class PromptsController < ApplicationController
    layout "active_prompt/admin"
      before_action :set_prompt, only: [:show, :edit, :update, :destroy]
      
      def index
        @prompts = ActivePrompt::Prompt.by_name
      end
      
      def show
      end
      
      def new
        @prompt = ActivePrompt::Prompt.new
      end
      
      def create
        @prompt = ActivePrompt::Prompt.new(prompt_params)
        
        if @prompt.save
          @prompt.sync_parameters!
          redirect_to prompt_path(@prompt), notice: 'Prompt was successfully created.'
        else
          render :new, status: :unprocessable_entity
        end
      end
      
      def edit
      end
      
      def update
        if @prompt.update(prompt_params)
          @prompt.sync_parameters!
          redirect_to prompt_path(@prompt), notice: 'Prompt was successfully updated.'
        else
          render :edit, status: :unprocessable_entity
        end
      end
      
      def destroy
        @prompt.destroy
        redirect_to prompts_path, notice: 'Prompt was successfully deleted.'
      end
      
      private
      
      def set_prompt
        @prompt = ActivePrompt::Prompt.find(params[:id])
      end
      
      def prompt_params
        params.require(:prompt).permit(:name, :description, :content, :system_message, :model, :temperature, :max_tokens, :status)
      end
  end
end