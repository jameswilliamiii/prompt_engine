require 'rails_helper'

RSpec.describe "PromptEngine Authentication", type: :request do
  describe "default behavior" do
    it "allows access without any authentication configured" do
      get prompt_engine.prompts_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "ActiveSupport hook mechanism" do
    it "allows host applications to add authentication" do
      # This test verifies the hook is available
      hook_called = false
      
      ActiveSupport.on_load(:prompt_engine_application_controller) do
        hook_called = true
      end
      
      # Trigger the hook by accessing the controller
      PromptEngine::ApplicationController.new
      
      expect(hook_called).to be true
    end
  end

  describe "middleware authentication" do
    it "allows middleware to be added to the engine" do
      # Verify the middleware stack is accessible
      expect(PromptEngine::Engine.middleware).to respond_to(:use)
    end
  end
  
  describe "accessing main app helpers" do
    it "provides access to main_app routes" do
      controller = PromptEngine::ApplicationController.new
      expect(controller).to respond_to(:main_app)
    end
  end
end