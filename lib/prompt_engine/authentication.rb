module PromptEngine
  module Authentication
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_prompt_engine_user!
    end

    private

    def authenticate_prompt_engine_user!
      return true unless PromptEngine.authentication_enabled

      # Check if HTTP Basic Auth is configured
      if PromptEngine.use_http_basic_auth?
        authenticate_or_request_with_http_basic("PromptEngine Admin") do |username, password|
          ActiveSupport::SecurityUtils.secure_compare(
            PromptEngine.http_basic_auth_name.to_s, username.to_s
          ) & ActiveSupport::SecurityUtils.secure_compare(
            PromptEngine.http_basic_auth_password.to_s, password.to_s
          )
        end
      else
        # Allow host app to define custom authentication
        # By default, return true to allow access
        # Host apps can override this method
        true
      end
    end
  end
end
