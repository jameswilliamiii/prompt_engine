module ActivePrompt
  class PlaygroundController < ApplicationController
    layout "active_prompt/admin"
    before_action :set_prompt

    def show
      @parameters = ParameterParser.new(@prompt.content).extract_parameters.map { |p| p[:name] }
    end

    def execute
      executor = PlaygroundExecutor.new(
        prompt: @prompt,
        provider: params[:provider],
        api_key: params[:api_key],
        parameters: params[:parameters]
      )
      
      begin
        result = executor.execute
        @response = result[:response]
        @execution_time = result[:execution_time]
        @token_count = result[:token_count]
        @model = result[:model]
        @provider = result[:provider]
        
        # Store the rendered prompt for display
        parser = ParameterParser.new(@prompt.content)
        @rendered_prompt = parser.replace_parameters(params[:parameters])
      rescue => e
        @error = e.message
      end
      
      render :result
    end

    private

    def set_prompt
      @prompt = Prompt.find(params[:id])
    end
  end
end