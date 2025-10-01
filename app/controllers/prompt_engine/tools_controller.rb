module PromptEngine
  class ToolsController < ApplicationController
    before_action :set_prompt, except: [:discover]

    # GET /tools/discover
    def discover
      tools = PromptEngine::ToolDiscoveryService.discover_tools
      render json: { tools: tools }
    end

    # GET /prompts/:id/tools
    def index
      @available_tools = @prompt.available_tools
      @selected_tools = @prompt.selected_tools
    end

    # POST /prompts/:id/tools
    def create
      tool_class_name = params[:tool_class_name]
      
      if @prompt.add_tool(tool_class_name)
        @prompt.save!
        render json: { 
          success: true, 
          message: "Tool added successfully",
          tool: @prompt.tool_info(tool_class_name)
        }
      else
        render json: { 
          success: false, 
          message: "Failed to add tool. Tool may already be selected or not available." 
        }, status: :unprocessable_entity
      end
    end

    # DELETE /prompts/:id/tools/:tool_class_name
    def destroy
      tool_class_name = params[:id] # Tool class name is passed as :id
      
      if @prompt.remove_tool(tool_class_name)
        @prompt.save!
        render json: { 
          success: true, 
          message: "Tool removed successfully" 
        }
      else
        render json: { 
          success: false, 
          message: "Tool not found or could not be removed" 
        }, status: :unprocessable_entity
      end
    end

    # GET /prompts/:id/tools/available
    def available
      tools = @prompt.available_tools
      render json: { tools: tools }
    end

    private

    def set_prompt
      @prompt = PromptEngine::Prompt.find(params[:prompt_id])
    end
  end
end
