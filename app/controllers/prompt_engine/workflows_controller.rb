module PromptEngine
  class WorkflowsController < ApplicationController
    layout "prompt_engine/admin"
    before_action :set_workflow, only: [ :show, :edit, :update, :destroy ]

    def index
      @workflows = Workflow.all.order(:name)

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @workflows }
      end
    end

    def show
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @workflow }
      end
    end

    def new
      @workflow = Workflow.new
      @available_prompts = PromptEngine::Prompt.enabled.order(:name)
    end

    def edit
      @available_prompts = PromptEngine::Prompt.enabled.order(:name)
    end

    def create
      @workflow = Workflow.new(workflow_params)

      respond_to do |format|
        if @workflow.save
          format.html { redirect_to @workflow, notice: "Workflow was successfully created." }
          format.json { render json: @workflow, status: :created }
        else
          @available_prompts = PromptEngine::Prompt.enabled.order(:name)
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: { errors: @workflow.errors }, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        if @workflow.update(workflow_params)
          format.html { redirect_to @workflow, notice: "Workflow was successfully updated." }
          format.json { render json: @workflow }
        else
          @available_prompts = PromptEngine::Prompt.enabled.order(:name)
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: { errors: @workflow.errors }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @workflow.destroy
      respond_to do |format|
        format.html { redirect_to workflows_path, notice: "Workflow was successfully deleted." }
        format.json { head :no_content }
      end
    end

    private

    def set_workflow
      @workflow = Workflow.find(params[:id])
    end

    def workflow_params
      params.require(:workflow).permit(:name, :pass_original_input, steps: {}, conditions: {})
    end
  end
end
