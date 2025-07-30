require "rails_helper"

RSpec.describe "PromptEngine Authentication", type: :request do
  describe "default behavior" do
    it "allows access without any authentication configured by default" do
      get prompt_engine.prompts_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "ActiveSupport hook mechanism" do
    it "allows customization via ActiveSupport.on_load" do
      # This test verifies the hook mechanism is available
      hook_executed = false
      
      ActiveSupport.on_load(:prompt_engine_application_controller) do
        hook_executed = true
      end
      
      # Force loading of the controller class
      PromptEngine::ApplicationController
      
      expect(hook_executed).to be true
    end

    it "provides access to main_app helper in controllers" do
      controller = PromptEngine::ApplicationController.new
      expect(controller).to respond_to(:main_app)
    end
  end

  describe "authentication examples" do
    it "demonstrates HTTP Basic auth setup" do
      # This is a documentation test showing how to configure Basic Auth
      example_code = <<~RUBY
        # In config/initializers/prompt_engine.rb:
        PromptEngine::Engine.middleware.use(Rack::Auth::Basic) do |username, password|
          ActiveSupport::SecurityUtils.secure_compare(
            Rails.application.credentials.prompt_engine_username, username
          ) & ActiveSupport::SecurityUtils.secure_compare(
            Rails.application.credentials.prompt_engine_password, password
          )
        end
      RUBY

      expect(example_code).to include("Rack::Auth::Basic")
      expect(example_code).to include("secure_compare")
    end

    it "demonstrates Devise route-level authentication" do
      example_code = <<~RUBY
        # In config/routes.rb:
        Rails.application.routes.draw do
          authenticate :user do
            mount PromptEngine::Engine => "/prompt_engine"
          end
          
          # Or with role checking:
          authenticate :user, ->(user) { user.admin? } do
            mount PromptEngine::Engine => "/prompt_engine"
          end
        end
      RUBY

      expect(example_code).to include("authenticate :user")
      expect(example_code).to include("user.admin?")
    end

    it "demonstrates custom authentication via ActiveSupport hooks" do
      example_code = <<~RUBY
        # In config/initializers/prompt_engine.rb:
        ActiveSupport.on_load(:prompt_engine_application_controller) do
          before_action :authenticate_admin!
          
          private
          
          def authenticate_admin!
            unless current_user&.admin?
              redirect_to main_app.root_path, alert: "Not authorized"
            end
          end
          
          def current_user
            # Use your app's current user method
            main_app.current_user
          end
        end
      RUBY

      expect(example_code).to include("before_action :authenticate_admin!")
      expect(example_code).to include("main_app.current_user")
    end

    it "demonstrates session-based authentication" do
      example_code = <<~RUBY
        ActiveSupport.on_load(:prompt_engine_application_controller) do
          before_action :require_user_session

          private

          def require_user_session
            redirect_to main_app.login_path unless session[:user_id]
          end
        end
      RUBY

      expect(example_code).to include("session[:user_id]")
      expect(example_code).to include("redirect_to main_app.login_path")
    end

    it "demonstrates API token authentication" do
      example_code = <<~RUBY
        ActiveSupport.on_load(:prompt_engine_application_controller) do
          before_action :authenticate_api_token

          private

          def authenticate_api_token
            token = request.headers["X-API-Token"]
            unless valid_api_token?(token)
              render json: { error: 'Unauthorized' }, status: :unauthorized
            end
          end
          
          def valid_api_token?(token)
            # Implement your token validation logic
            ApiToken.active.exists?(token: token)
          end
        end
      RUBY

      expect(example_code).to include("request.headers[\"X-API-Token\"]")
      expect(example_code).to include("status: :unauthorized")
    end

    it "demonstrates multiple authentication methods" do
      example_code = <<~RUBY
        ActiveSupport.on_load(:prompt_engine_application_controller) do
          before_action :authenticate_by_any_method!
          
          private
          
          def authenticate_by_any_method!
            return if authenticated_via_session?
            return if authenticated_via_api_token?
            
            respond_to do |format|
              format.html { redirect_to main_app.login_path }
              format.json { render json: { error: 'Unauthorized' }, status: :unauthorized }
            end
          end
          
          def authenticated_via_session?
            current_user.present?
          end
          
          def authenticated_via_api_token?
            request.headers['X-API-Key'].present? &&
              ApiKey.active.exists?(key: request.headers['X-API-Key'])
          end
        end
      RUBY

      expect(example_code).to include("authenticate_by_any_method!")
      expect(example_code).to include("authenticated_via_session?")
      expect(example_code).to include("authenticated_via_api_token?")
    end
  end

  describe "engine middleware stack" do
    it "provides access to middleware configuration" do
      expect(PromptEngine::Engine.middleware).to respond_to(:use)
    end
  end
end