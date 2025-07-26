# PromptEngine Authentication Guide

This guide covers all authentication options available in PromptEngine, from basic setup to advanced configurations.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Authentication Methods](#authentication-methods)
  - [HTTP Basic Authentication](#http-basic-authentication)
  - [Devise Integration](#devise-integration)
  - [Custom Authentication](#custom-authentication)
  - [Middleware Authentication](#middleware-authentication)
- [Configuration](#configuration)
- [Security Best Practices](#security-best-practices)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Examples](#examples)

## Overview

PromptEngine provides flexible authentication to secure your admin interface. Authentication is enabled by default but requires configuration to be effective. Without configuration, the admin interface is accessible to everyone, which is suitable for development but not for production.

## Quick Start

The fastest way to secure PromptEngine is with HTTP Basic authentication:

```ruby
# config/initializers/prompt_engine.rb
PromptEngine.configure do |config|
  config.http_basic_auth_enabled = true
  config.http_basic_auth_name = "admin"
  config.http_basic_auth_password = "your_secure_password"
end
```

For production, use environment variables or Rails credentials:

```ruby
# Using environment variables
PromptEngine.configure do |config|
  config.http_basic_auth_enabled = true
  config.http_basic_auth_name = ENV['PROMPT_ENGINE_USERNAME']
  config.http_basic_auth_password = ENV['PROMPT_ENGINE_PASSWORD']
end

# Using Rails credentials
PromptEngine.configure do |config|
  config.http_basic_auth_enabled = true
  config.http_basic_auth_name = Rails.application.credentials.dig(:prompt_engine, :username)
  config.http_basic_auth_password = Rails.application.credentials.dig(:prompt_engine, :password)
end
```

## Authentication Methods

### HTTP Basic Authentication

HTTP Basic authentication is built into PromptEngine and provides a simple way to protect your admin interface.

#### Basic Setup

```ruby
# config/initializers/prompt_engine.rb
PromptEngine.configure do |config|
  config.http_basic_auth_enabled = true
  config.http_basic_auth_name = "admin"
  config.http_basic_auth_password = "secure_password"
end
```

#### Production Setup with Rails Credentials

First, add credentials:

```bash
rails credentials:edit
```

```yaml
# In credentials file
prompt_engine:
  username: your_username
  password: your_secure_password
```

Then configure PromptEngine:

```ruby
# config/initializers/prompt_engine.rb
PromptEngine.configure do |config|
  config.http_basic_auth_enabled = true
  config.http_basic_auth_name = Rails.application.credentials.dig(:prompt_engine, :username)
  config.http_basic_auth_password = Rails.application.credentials.dig(:prompt_engine, :password)
end
```

#### Security Features

- Uses `ActiveSupport::SecurityUtils.secure_compare` to prevent timing attacks
- Credentials are never logged
- Empty credentials are treated as invalid
- Works with all HTTP clients and browsers

### Devise Integration

If your application uses Devise, you can leverage its authentication:

#### Route-based Authentication

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Only authenticated users can access PromptEngine
  authenticate :user do
    mount PromptEngine::Engine => "/prompt_engine"
  end
  
  # Or with specific roles
  authenticate :user, ->(user) { user.admin? } do
    mount PromptEngine::Engine => "/prompt_engine"
  end
  
  # Or with multiple conditions
  authenticate :user, ->(user) { user.admin? && user.active? } do
    mount PromptEngine::Engine => "/prompt_engine"
  end
end
```

#### Controller-based Authentication

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  # Use Devise helpers
  before_action :authenticate_user!
  before_action :require_admin!
  
  private
  
  def require_admin!
    unless current_user.admin?
      redirect_to root_path, alert: "Not authorized"
    end
  end
end
```

### Custom Authentication

Integrate PromptEngine with your existing authentication system:

#### Basic Custom Authentication

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  before_action :authenticate_prompt_engine_access!
  
  private
  
  def authenticate_prompt_engine_access!
    unless session[:user_id] && User.find(session[:user_id]).can_access_prompts?
      render plain: "Unauthorized", status: :unauthorized
    end
  end
end
```

#### With Current User

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  before_action :require_prompt_admin!
  
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
  
  helper_method :current_user
  
  private
  
  def require_prompt_admin!
    unless current_user&.has_role?(:prompt_admin)
      redirect_to main_app.root_path, alert: "Access denied"
    end
  end
end
```

#### API Token Authentication

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  before_action :authenticate_api_token!
  
  private
  
  def authenticate_api_token!
    token = request.headers['Authorization']&.split(' ')&.last
    api_key = ApiKey.active.find_by(token: token)
    
    unless api_key&.has_permission?('prompt_engine.admin')
      render json: { error: 'Invalid API key' }, status: :unauthorized
    end
  end
end
```

### Middleware Authentication

For advanced authentication needs, you can add Rack middleware:

#### Custom Middleware

```ruby
# config/initializers/prompt_engine.rb
class PromptEngineAuth
  def initialize(app)
    @app = app
  end
  
  def call(env)
    request = Rack::Request.new(env)
    
    # Only check authentication for PromptEngine routes
    if request.path.start_with?('/prompt_engine')
      # Your authentication logic here
      unless authenticated?(request)
        return [401, {'Content-Type' => 'text/plain'}, ['Unauthorized']]
      end
    end
    
    @app.call(env)
  end
  
  private
  
  def authenticated?(request)
    # Check cookies, headers, etc.
    auth_token = request.cookies['auth_token']
    AuthToken.valid?(auth_token)
  end
end

PromptEngine::Engine.middleware.use PromptEngineAuth
```

#### IP Whitelisting

```ruby
# config/initializers/prompt_engine.rb
require 'ipaddr'

class IPWhitelist
  ALLOWED_IPS = [
    IPAddr.new('10.0.0.0/8'),
    IPAddr.new('192.168.0.0/16'),
    IPAddr.new('127.0.0.1')
  ].freeze
  
  def initialize(app)
    @app = app
  end
  
  def call(env)
    request = Rack::Request.new(env)
    
    if request.path.start_with?('/prompt_engine')
      client_ip = IPAddr.new(request.ip)
      
      unless ALLOWED_IPS.any? { |allowed| allowed.include?(client_ip) }
        return [403, {'Content-Type' => 'text/plain'}, ['Forbidden']]
      end
    end
    
    @app.call(env)
  end
end

PromptEngine::Engine.middleware.use IPWhitelist
```

## Configuration

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `authentication_enabled` | Boolean | `true` | Master switch for all authentication |
| `http_basic_auth_enabled` | Boolean | `false` | Enable HTTP Basic authentication |
| `http_basic_auth_name` | String | `nil` | Username for HTTP Basic auth |
| `http_basic_auth_password` | String | `nil` | Password for HTTP Basic auth |

### Configuration Methods

#### Block Configuration

```ruby
PromptEngine.configure do |config|
  config.authentication_enabled = true
  config.http_basic_auth_enabled = true
  config.http_basic_auth_name = "admin"
  config.http_basic_auth_password = "password"
end
```

#### Direct Assignment

```ruby
PromptEngine.authentication_enabled = true
PromptEngine.http_basic_auth_enabled = true
PromptEngine.http_basic_auth_name = "admin"
PromptEngine.http_basic_auth_password = "password"
```

### Environment-based Configuration

```ruby
# config/initializers/prompt_engine.rb
PromptEngine.configure do |config|
  case Rails.env
  when 'development'
    config.authentication_enabled = false
  when 'staging'
    config.http_basic_auth_enabled = true
    config.http_basic_auth_name = ENV['STAGING_USERNAME']
    config.http_basic_auth_password = ENV['STAGING_PASSWORD']
  when 'production'
    config.http_basic_auth_enabled = true
    config.http_basic_auth_name = Rails.application.credentials.prompt_engine_username
    config.http_basic_auth_password = Rails.application.credentials.prompt_engine_password
  end
end
```

## Security Best Practices

### 1. Always Enable Authentication in Production

```ruby
# config/initializers/prompt_engine.rb
if Rails.env.production?
  raise "PromptEngine authentication must be configured in production" unless PromptEngine.authentication_enabled
  
  # Ensure credentials are set
  if PromptEngine.http_basic_auth_enabled
    raise "HTTP Basic auth credentials not set" if PromptEngine.http_basic_auth_name.blank? || PromptEngine.http_basic_auth_password.blank?
  end
end
```

### 2. Use Strong Passwords

```ruby
# Generate strong passwords
require 'securerandom'
strong_password = SecureRandom.urlsafe_base64(32)
```

### 3. Store Credentials Securely

Never commit credentials to version control. Use:

- Rails encrypted credentials
- Environment variables
- Secret management services (AWS Secrets Manager, Vault, etc.)

### 4. Use HTTPS

Always use HTTPS in production to encrypt credentials in transit:

```ruby
# config/environments/production.rb
config.force_ssl = true
```

### 5. Implement Rate Limiting

Protect against brute force attacks:

```ruby
# Using rack-attack gem
Rack::Attack.throttle('prompt_engine/auth', limit: 5, period: 1.minute) do |req|
  req.path.start_with?('/prompt_engine') && req.ip
end
```

### 6. Audit Logging

Log authentication attempts:

```ruby
ActiveSupport.on_load(:prompt_engine_application_controller) do
  after_action :log_access
  
  private
  
  def log_access
    Rails.logger.info "[PromptEngine] Access by #{current_user&.email || 'anonymous'} to #{request.path}"
  end
end
```

## Testing

### Disable Authentication in Tests

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.before(:each) do
    PromptEngine.authentication_enabled = false
  end
  
  config.after(:each) do
    PromptEngine.authentication_enabled = true
  end
end
```

### Test with Authentication

```ruby
# spec/requests/prompt_engine_spec.rb
RSpec.describe "PromptEngine with auth" do
  before do
    PromptEngine.configure do |config|
      config.authentication_enabled = true
      config.http_basic_auth_enabled = true
      config.http_basic_auth_name = "test"
      config.http_basic_auth_password = "password"
    end
  end
  
  it "requires authentication" do
    get prompt_engine.prompts_path
    expect(response).to have_http_status(:unauthorized)
  end
  
  it "allows access with valid credentials" do
    get prompt_engine.prompts_path, headers: {
      "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("test", "password")
    }
    expect(response).to have_http_status(:success)
  end
end
```

### Test Helpers

```ruby
# spec/support/prompt_engine_auth_helper.rb
module PromptEngineAuthHelper
  def with_prompt_engine_auth(username: "admin", password: "password")
    old_settings = {
      enabled: PromptEngine.authentication_enabled,
      http_enabled: PromptEngine.http_basic_auth_enabled,
      name: PromptEngine.http_basic_auth_name,
      password: PromptEngine.http_basic_auth_password
    }
    
    PromptEngine.configure do |config|
      config.authentication_enabled = true
      config.http_basic_auth_enabled = true
      config.http_basic_auth_name = username
      config.http_basic_auth_password = password
    end
    
    yield
  ensure
    PromptEngine.authentication_enabled = old_settings[:enabled]
    PromptEngine.http_basic_auth_enabled = old_settings[:http_enabled]
    PromptEngine.http_basic_auth_name = old_settings[:name]
    PromptEngine.http_basic_auth_password = old_settings[:password]
  end
  
  def prompt_engine_auth_headers(username: "admin", password: "password")
    {
      "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
    }
  end
end

RSpec.configure do |config|
  config.include PromptEngineAuthHelper
end
```

## Troubleshooting

### Authentication Not Working

1. Check if authentication is enabled:
   ```ruby
   Rails.console
   > PromptEngine.authentication_enabled
   # Should return true
   ```

2. Check HTTP Basic auth configuration:
   ```ruby
   > PromptEngine.use_http_basic_auth?
   # Should return true if properly configured
   ```

3. Verify credentials are set:
   ```ruby
   > PromptEngine.http_basic_auth_name.present?
   > PromptEngine.http_basic_auth_password.present?
   # Both should return true
   ```

### Custom Authentication Not Triggering

1. Ensure the initializer is loaded:
   ```bash
   rails runner "puts ActiveSupport.on_load(:prompt_engine_application_controller) { puts 'Hook loaded' }"
   ```

2. Check load order in development:
   ```ruby
   # config/environments/development.rb
   config.eager_load = true  # Temporarily enable to test
   ```

### Devise Integration Issues

1. Ensure Devise is initialized before PromptEngine
2. Check that Devise routes are defined before mounting PromptEngine
3. Verify Devise helpers are available:
   ```ruby
   Rails.console
   > PromptEngine::ApplicationController.new.respond_to?(:authenticate_user!)
   ```

## Examples

### Multi-tenant Application

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  before_action :authenticate_tenant_admin!
  
  private
  
  def authenticate_tenant_admin!
    unless current_user&.tenant_admin? && current_user.tenant == current_tenant
      redirect_to main_app.root_path, alert: "Access denied"
    end
  end
  
  def current_tenant
    @current_tenant ||= Tenant.find_by(subdomain: request.subdomain)
  end
end
```

### OAuth2 Integration

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  before_action :verify_oauth_token!
  
  private
  
  def verify_oauth_token!
    token = request.headers['Authorization']&.split(' ')&.last
    
    begin
      decoded_token = JWT.decode(token, Rails.application.credentials.jwt_secret)
      @current_user_id = decoded_token.first['user_id']
      
      unless User.find(@current_user_id).can_manage_prompts?
        render json: { error: 'Insufficient permissions' }, status: :forbidden
      end
    rescue JWT::DecodeError
      render json: { error: 'Invalid token' }, status: :unauthorized
    end
  end
end
```

### Two-Factor Authentication

```ruby
# config/initializers/prompt_engine.rb
ActiveSupport.on_load(:prompt_engine_application_controller) do
  before_action :require_two_factor!
  
  private
  
  def require_two_factor!
    if current_user && !current_user.two_factor_verified?(session[:two_factor_token])
      redirect_to main_app.two_factor_path(return_to: request.fullpath)
    end
  end
end
```

## Contributing

If you have ideas for improving authentication in PromptEngine, please [open an issue](https://github.com/yourusername/prompt_engine/issues) or submit a pull request.