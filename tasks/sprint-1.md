# Sprint 1: ActivePrompt Rails Engine Setup

## Sprint Goal
Set up the ActivePrompt Rails engine with proper structure, configuration, and a working dummy app for local development and testing.

## Tasks

### 1. Generate Rails Engine (Priority: High)
- [ ] Run `rails plugin new active_prompt --mountable --skip-test --dummy-path=spec/dummy`
- [ ] Verify directory structure is created correctly
- [ ] Ensure engine.rb file is properly configured with isolated namespace

### 2. Configure Engine Gemspec (Priority: High)
- [ ] Update active_prompt.gemspec with proper metadata
- [ ] Add runtime dependencies (Rails version constraints)
- [ ] Add development dependencies (rspec-rails, factory_bot_rails, vcr)
- [ ] Configure files to be included in the gem

### 3. Set Up RSpec Testing Framework (Priority: High)
- [ ] Run `rails g rspec:install` in the engine root
- [ ] Configure spec_helper.rb and rails_helper.rb
- [ ] Set up proper paths to dummy app in rails_helper.rb
- [ ] Configure migration paths for testing
- [ ] Add FactoryBot configuration

### 4. Configure Engine Initialization (Priority: High)
- [ ] Update lib/active_prompt/engine.rb with proper configuration
- [ ] Set up generators configuration for RSpec
- [ ] Configure asset pipeline settings
- [ ] Set up proper namespacing

### 5. Set Up Basic Routing Structure (Priority: Medium)
- [ ] Create config/routes.rb with engine routes
- [ ] Add namespace for admin interface
- [ ] Create placeholder route for prompts resource

### 6. Create Base Controllers (Priority: Medium)
- [ ] Generate ApplicationController within engine namespace
- [ ] Generate Admin::BaseController for admin interface
- [ ] Set up proper inheritance and namespacing

### 7. Configure Dummy App (Priority: High)
- [ ] Verify spec/dummy app structure
- [ ] Mount engine in dummy app's routes.rb
- [ ] Add database configuration for dummy app
- [ ] Create basic layout for testing

### 8. Set Up Development Database (Priority: Medium)
- [ ] Configure database.yml in dummy app
- [ ] Create initial migration for prompts table
- [ ] Run migrations in dummy app
- [ ] Verify database connectivity

### 9. Create Basic Prompt Model (Priority: Medium)
- [ ] Generate Prompt model with basic attributes
- [ ] Add validations
- [ ] Create initial migration
- [ ] Write basic model specs

### 10. Add Development Scripts (Priority: Low)
- [ ] Create bin/setup script for easy development setup
- [ ] Add rake tasks for common development tasks
- [ ] Document setup process in README

### 11. Verify Local Development Setup (Priority: High)
- [ ] Start dummy app with `rails s` from spec/dummy
- [ ] Verify engine is mounted and accessible
- [ ] Confirm routes are working
- [ ] Test that assets are loading properly

### 12. Set Up Git and Initial Commit (Priority: Low)
- [ ] Initialize git repository
- [ ] Create .gitignore file
- [ ] Make initial commit with base structure

## Success Criteria
- Engine is properly generated with mountable configuration
- RSpec is configured and working with dummy app
- Dummy app can be started locally with `cd spec/dummy && rails s`
- Engine is mounted and accessible at `/active_prompt` route
- Basic model and migration structure is in place
- All tests are passing (even if minimal)

## Notes
- Focus on proper structure and configuration over features
- Ensure all Rails engine conventions are followed
- Keep dependencies minimal for MVP
- Document any deviations from standard Rails engine practices