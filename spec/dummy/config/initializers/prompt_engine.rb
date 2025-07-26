# Example PromptEngine authentication configuration
#
# Uncomment and modify the configuration below to enable authentication

# PromptEngine.configure do |config|
#   # Enable authentication (default: true)
#   config.authentication_enabled = true
#
#   # HTTP Basic Authentication
#   # Uncomment to enable HTTP Basic auth
#   # config.http_basic_auth_enabled = true
#   # config.http_basic_auth_name = "admin"
#   # config.http_basic_auth_password = "secure_password"
#
#   # Or use Rails credentials for production:
#   # config.http_basic_auth_name = Rails.application.credentials.prompt_engine_username
#   # config.http_basic_auth_password = Rails.application.credentials.prompt_engine_password
# end

# Custom authentication using ActiveSupport hook
# Uncomment to add custom authentication logic
#
# ActiveSupport.on_load(:prompt_engine_application_controller) do
#   before_action do
#     # Example: Check if user is authenticated via your app's auth system
#     # raise ActionController::RoutingError.new('Not Found') unless current_user&.admin?
#   end
#
#   def current_user
#     # Your authentication logic here
#     # @current_user ||= User.find_by(id: session[:user_id])
#   end
# end

# For development/testing: Disable authentication
# WARNING: Do not use in production!
PromptEngine.configure do |config|
  config.authentication_enabled = false
end