# PromptEngine Authentication Guide

PromptEngine provides flexible authentication options that integrate seamlessly with your Rails application's existing authentication system. Since prompt templates may contain sensitive business logic or data, it's important to properly secure access to the PromptEngine admin interface.

## Authentication Options

### Option 1: Route-level Authentication with Devise

If you're using Devise, you can authenticate at the routing level:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Require any authenticated user
  authenticate :user do
    mount PromptEngine::Engine => "/prompt_engine"
  end
  
  # Or require specific role/permission
  authenticate :user, ->(user) { user.admin? } do
    mount PromptEngine::Engine => "/prompt_engine"
  end
  
  # Or with a more complex check
  authenticate :user, ->(user) { user.has_role?(:prompt_manager) || user.admin? } do
    mount PromptEngine::Engine => "/prompt_engine"
  end
end
```

### Option 2: Basic Authentication with Middleware

For simple deployments or staging environments, you can use HTTP Basic Authentication:

```ruby
# config/initializers/prompt_engine.rb
PromptEngine::Engine.middleware.use(Rack::Auth::Basic) do |username, password|
  ActiveSupport::SecurityUtils.secure_compare(
    Rails.application.credentials.prompt_engine_username, username
  ) & ActiveSupport::SecurityUtils.secure_compare(
    Rails.application.credentials.prompt_engine_password, password
  )
end
```

Configure your credentials:

```bash
rails credentials:edit
```

```yaml
prompt_engine_username: admin
prompt_engine_password: secure_password_here
```

### Option 3: Custom Authentication with ActiveSupport Hooks

For maximum flexibility, you can extend PromptEngine's ApplicationController to use your application's authentication system:

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  # The context here is PromptEngine::ApplicationController
  
  before_action :authenticate_admin!
  
  private
  
  def authenticate_admin!
    unless current_user&.can_manage_prompts?
      redirect_to main_app.root_path, alert: "Not authorized"
    end
  end
  
  def current_user
    # Use your app's current user method
    # For example, if using Devise:
    main_app.current_user
  end
end
```

### Option 4: Rails 8 Built-in Authentication

If you're using Rails 8's new authentication generator, PromptEngine works seamlessly:

First, generate Rails authentication if you haven't already:

```bash
rails generate authentication
```

Then use the route-level authentication:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Using Rails 8's authenticated constraint
  constraints ->(request) { Current.session = Session.find_by(id: request.session[:session_id]) } do
    mount PromptEngine::Engine => "/prompt_engine"
  end
end
```

Or customize via ActiveSupport hook:

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  include Authentication # Rails 8's authentication concern
  
  before_action :require_authentication
  
  # Optionally add role checking
  before_action do
    redirect_to root_path unless Current.user&.admin?
  end
end
```

### Option 5: Custom Authentication Systems

For other authentication systems (like Authlogic, Sorcery, or custom implementations):

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  # Include your authentication module
  include MyApp::Authentication
  
  before_action :require_login
  before_action :require_admin_role
  
  private
  
  def require_admin_role
    unless current_user.has_permission?(:manage_prompts)
      render plain: "403 Forbidden", status: :forbidden
    end
  end
end
```

## Disabling Authentication (Development Only)

For development environments where authentication isn't needed:

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  # Skip all authentication in development
  skip_before_action :authenticate_user! if Rails.env.development?
end
```

**⚠️ WARNING**: Never disable authentication in production!

## API Authentication

If you plan to build API endpoints that use PromptEngine, you can add token-based authentication:

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  before_action :authenticate_api_request, if: :api_request?
  
  private
  
  def api_request?
    request.format.json? || request.headers['Accept']&.include?('application/json')
  end
  
  def authenticate_api_request
    token = request.headers['Authorization']&.split(' ')&.last
    
    unless valid_api_token?(token)
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
  
  def valid_api_token?(token)
    # Implement your token validation logic
    ApiToken.active.exists?(token: token)
  end
end
```

## Multiple Authentication Methods

You can combine authentication methods for different scenarios:

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  # Skip default authentication
  skip_before_action :authenticate_user!, raise: false
  
  # Add custom authentication logic
  before_action :authenticate_by_any_method!
  
  private
  
  def authenticate_by_any_method!
    return if authenticated_via_session?
    return if authenticated_via_basic_auth?
    return if authenticated_via_api_token?
    
    redirect_to main_app.login_path
  end
  
  def authenticated_via_session?
    current_user.present?
  end
  
  def authenticated_via_basic_auth?
    authenticate_with_http_basic do |username, password|
      username == Rails.application.credentials.prompt_engine_username &&
      password == Rails.application.credentials.prompt_engine_password
    end
  end
  
  def authenticated_via_api_token?
    # Check for API token in headers
    request.headers['X-API-Key'] == Rails.application.credentials.prompt_engine_api_key
  end
end
```

## Testing with Authentication

When writing tests, you'll need to handle authentication:

```ruby
# spec/support/prompt_engine_auth.rb
module PromptEngineAuthHelper
  def login_as_admin
    user = create(:user, :admin)
    sign_in user # If using Devise
  end
  
  def with_basic_auth
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'password')
    { 'HTTP_AUTHORIZATION' => credentials }
  end
end

# In your tests
RSpec.describe "PromptEngine Admin", type: :request do
  it "requires authentication" do
    get prompt_engine.prompts_path
    expect(response).to redirect_to(login_path)
  end
  
  it "allows authenticated access" do
    login_as_admin
    get prompt_engine.prompts_path
    expect(response).to be_successful
  end
end
```

## Security Best Practices

1. **Always authenticate in production** - Never leave the admin interface unprotected
2. **Use secure passwords** - If using basic auth, use strong, unique passwords
3. **Implement proper authorization** - Not just authentication, but also check permissions
4. **Audit access** - Log who accesses and modifies prompts
5. **Use HTTPS** - Always serve PromptEngine over HTTPS in production
6. **Rotate credentials** - Regularly update API keys and passwords

## Troubleshooting

### "undefined method 'current_user'"

Make sure to define the method or include the appropriate module:

```ruby
ActiveSupport.on_load(:prompt_engine_application_controller) do
  def current_user
    # Define how to get the current user in your app
    User.find_by(id: session[:user_id])
  end
end
```

### Infinite redirect loops

Ensure you're not redirecting to a path that also requires authentication:

```ruby
def authenticate_admin!
  unless current_user&.admin?
    redirect_to main_app.root_path # Not another protected path
  end
end
```

### Basic auth not working

Check that credentials are properly set:

```bash
rails credentials:show
```

### Methods not available in engine controller

Use `main_app` helper to access main application's routes and helpers:

```ruby
redirect_to main_app.login_path
main_app.current_user
```

## Summary

PromptEngine's authentication is designed to be flexible and work with your existing authentication system. Choose the approach that best fits your application:

- **Devise users**: Use route-level authentication
- **Simple deployments**: Use basic authentication
- **Custom needs**: Use ActiveSupport hooks
- **Rails 8 apps**: Use the built-in authentication
- **API access**: Add token-based authentication

The key principle is that PromptEngine doesn't impose its own authentication system but integrates with yours, giving you full control over who can access and manage your AI prompts.