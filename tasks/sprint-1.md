# Sprint 1: ActivePrompt Rails Engine Setup

## Sprint Goal
Set up the ActivePrompt Rails engine with proper structure, configuration, and a working dummy app for local development and testing.

## Tasks

### 1. Generate Rails Engine (Priority: High)
- [x] Run `rails plugin new active_prompt --mountable --skip-test --dummy-path=spec/dummy`
- [x] Verify directory structure is created correctly
- [x] Ensure engine.rb file is properly configured with isolated namespace

### 2. Configure Engine Gemspec (Priority: High)
- [x] Update active_prompt.gemspec with proper metadata
- [x] Add runtime dependencies (Rails version constraints)
- [x] Add development dependencies (rspec-rails, factory_bot_rails, vcr)
- [x] Configure files to be included in the gem

### 3. Set Up RSpec Testing Framework (Priority: High)
- [x] Run `rails g rspec:install` in the engine root
- [x] Configure spec_helper.rb and rails_helper.rb
- [x] Set up proper paths to dummy app in rails_helper.rb
- [x] Configure migration paths for testing
- [x] Add FactoryBot configuration

### 4. Configure Engine Initialization (Priority: High)
- [x] Update lib/active_prompt/engine.rb with proper configuration
- [x] Set up generators configuration for RSpec
- [x] Configure asset pipeline settings
- [x] Set up proper namespacing

### 5. Set Up Basic Routing Structure (Priority: Medium)
- [x] Create config/routes.rb with engine routes
- [x] Add namespace for admin interface
- [x] Create placeholder route for prompts resource

### 6. Create Base Controllers (Priority: Medium)
- [x] Generate ApplicationController within engine namespace
- [x] Generate Admin::BaseController for admin interface
- [x] Set up proper inheritance and namespacing

### 7. Configure Dummy App (Priority: High)
- [x] Verify spec/dummy app structure
- [x] Mount engine in dummy app's routes.rb
- [x] Add database configuration for dummy app
- [x] Create basic layout for testing

### 8. Set Up Development Database (Priority: Medium)
- [x] Configure database.yml in dummy app
- [x] Create initial migration for prompts table
- [x] Run migrations in dummy app
- [x] Verify database connectivity

### 9. Create Basic Prompt Model (Priority: Medium)
- [x] Generate Prompt model with basic attributes
- [x] Add validations
- [x] Create initial migration
- [ ] Write basic model specs

### 10. Add Development Scripts (Priority: Low)
- [ ] Create bin/setup script for easy development setup
- [ ] Add rake tasks for common development tasks
- [ ] Document setup process in README

### 11. Verify Local Development Setup (Priority: High)
- [x] Start dummy app with `rails s` from spec/dummy
- [x] Verify engine is mounted and accessible
- [x] Confirm routes are working
- [x] Test that assets are loading properly

### 12. Set Up Git and Initial Commit (Priority: Low)
- [x] Initialize git repository
- [x] Create .gitignore file
- [x] Make initial commit with base structure

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