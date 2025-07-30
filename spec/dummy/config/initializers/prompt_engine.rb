# PromptEngine Authentication Configuration
#
# PromptEngine doesn't require authentication by default.
# Choose one of the authentication methods below based on your needs.
# See AUTH.md for detailed documentation and examples.

# Option 1: Basic Authentication (for simple deployments)
# PromptEngine::Engine.middleware.use(Rack::Auth::Basic) do |username, password|
#   ActiveSupport::SecurityUtils.secure_compare(
#     Rails.application.credentials.prompt_engine_username, username
#   ) & ActiveSupport::SecurityUtils.secure_compare(
#     Rails.application.credentials.prompt_engine_password, password
#   )
# end

# Option 2: Custom Authentication (integrate with your app's auth system)
# ActiveSupport.on_load(:prompt_engine_application_controller) do
#   before_action :authenticate_admin!
#   
#   private
#   
#   def authenticate_admin!
#     redirect_to main_app.root_path unless current_user&.admin?
#   end
#   
#   def current_user
#     # Your app's current user method
#     @current_user ||= User.find_by(id: session[:user_id])
#   end
# end

# For development: No authentication
# This is the default for the dummy app
# WARNING: Do not use in production!
