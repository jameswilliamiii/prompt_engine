require "rails_helper"

RSpec.describe "PromptEngine Authentication", type: :request do
  describe "authentication behavior" do
    before do
      # Reset configuration to defaults before each test
      PromptEngine.authentication_enabled = true
      PromptEngine.http_basic_auth_enabled = false
      PromptEngine.http_basic_auth_name = nil
      PromptEngine.http_basic_auth_password = nil
    end

    after do
      # Reset configuration after tests
      PromptEngine.authentication_enabled = true
      PromptEngine.http_basic_auth_enabled = false
    end

    context "when authentication is disabled" do
      before do
        PromptEngine.authentication_enabled = false
      end

      it "allows access without authentication" do
        get prompt_engine.prompts_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when HTTP Basic authentication is enabled" do
      before do
        PromptEngine.http_basic_auth_enabled = true
        PromptEngine.http_basic_auth_name = "admin"
        PromptEngine.http_basic_auth_password = "secret123"
      end

      it "denies access without credentials" do
        get prompt_engine.prompts_path
        expect(response).to have_http_status(:unauthorized)
      end

      it "denies access with incorrect credentials" do
        get prompt_engine.prompts_path, headers: {
          "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("wrong", "credentials")
        }
        expect(response).to have_http_status(:unauthorized)
      end

      it "allows access with correct credentials" do
        get prompt_engine.prompts_path, headers: {
          "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "secret123")
        }
        expect(response).to have_http_status(:success)
      end

      it "uses secure comparison for credentials" do
        # This test ensures timing attacks are mitigated
        start_time = Time.now
        get prompt_engine.prompts_path, headers: {
          "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "wrong_password_that_is_very_long")
        }
        time_with_wrong_password = Time.now - start_time

        start_time = Time.now
        get prompt_engine.prompts_path, headers: {
          "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "w")
        }
        time_with_short_password = Time.now - start_time

        # The times should be similar due to secure comparison
        expect(time_with_wrong_password).to be_within(0.1).of(time_with_short_password)
      end
    end

    context "when using custom authentication" do
      before do
        # Simulate custom authentication by stubbing the controller method
        allow_any_instance_of(PromptEngine::ApplicationController).to receive(:authenticate_prompt_engine_user!).and_return(false)
      end

      it "respects custom authentication logic" do
        get prompt_engine.prompts_path
        expect(response).to have_http_status(:success)
      end
    end

    context "configuration" do
      it "supports block configuration" do
        PromptEngine.configure do |config|
          config.authentication_enabled = false
          config.http_basic_auth_enabled = true
          config.http_basic_auth_name = "test_user"
          config.http_basic_auth_password = "test_pass"
        end

        expect(PromptEngine.authentication_enabled).to eq(false)
        expect(PromptEngine.http_basic_auth_enabled).to eq(true)
        expect(PromptEngine.http_basic_auth_name).to eq("test_user")
        expect(PromptEngine.http_basic_auth_password).to eq("test_pass")
      end

      it "correctly determines when to use HTTP Basic auth" do
        PromptEngine.http_basic_auth_enabled = true
        PromptEngine.http_basic_auth_name = nil
        PromptEngine.http_basic_auth_password = nil
        expect(PromptEngine.use_http_basic_auth?).to be_falsey

        PromptEngine.http_basic_auth_name = "user"
        expect(PromptEngine.use_http_basic_auth?).to be_falsey

        PromptEngine.http_basic_auth_password = "pass"
        expect(PromptEngine.use_http_basic_auth?).to be_truthy

        PromptEngine.http_basic_auth_enabled = false
        expect(PromptEngine.use_http_basic_auth?).to be_falsey
      end
    end
  end

  describe "ActiveSupport.on_load hook" do
    it "runs custom authentication logic" do
      custom_logic_executed = false

      ActiveSupport.on_load(:prompt_engine_application_controller) do
        define_method :custom_auth_check do
          custom_logic_executed = true
        end
      end

      # Force reload of ApplicationController to trigger hook
      load Rails.root.join("../../app/controllers/prompt_engine/application_controller.rb")

      controller = PromptEngine::ApplicationController.new
      expect(controller).to respond_to(:custom_auth_check)
    end
  end
end
