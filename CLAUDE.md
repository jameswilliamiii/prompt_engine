# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ActivePrompt Rails Engine

ActivePrompt is a mountable Rails engine for AI prompt management. It provides a centralized admin interface where teams can create, version, test, and optimize their AI prompts without deploying code changes.

## Development Commands

### Running the Development Server
```bash
cd spec/dummy && rails s
```
Access the admin interface at `http://localhost:3000/active_prompt`

### Database Setup
```bash
cd spec/dummy
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed  # Loads sample prompts
```

### Running Tests
```bash
bundle exec rspec                           # Run all tests with coverage
bundle exec rspec spec/models               # Run model tests  
bundle exec rspec spec/requests             # Run request specs (controllers)
bundle exec rspec spec/system               # Run system tests
bundle exec rspec path/to/spec.rb           # Run specific test file
bundle exec rspec path/to/spec.rb:42        # Run specific test by line number
bundle exec rspec --format documentation    # Run with detailed output

# Coverage report
open coverage/index.html                    # View SimpleCov coverage report
```

### Rake Tasks
```bash
bundle exec rake setup                      # Setup dummy app for development
bundle exec rake spec                       # Run all specs
bin/rails active_prompt:install:migrations  # Install engine migrations in host app
```

## Architecture Overview

### Core Models & Relationships

**ActivePrompt::Prompt**
- Central model containing prompt templates with `{{variable}}` syntax
- Has many versions (auto-versioned on content/system_message changes)
- Has many parameters (auto-detected from variables)
- Status enum: draft, active, archived
- Key method: `render(variables: {})` for template rendering

**ActivePrompt::PromptVersion**
- Immutable snapshots of prompts
- Auto-incremented version numbers
- Stores content, system_message, model_config at time of creation
- Key method: `restore!` to revert prompt to this version

**ActivePrompt::Parameter**
- Defines expected variables with types and validation
- Types: string, integer, decimal, boolean, datetime, date, array, json
- Auto-generates appropriate form inputs

### Service Objects

**VariableDetector**
- Extracts `{{variables}}` from prompt content
- Infers types from variable names (e.g., `_at` → datetime)
- Validates provided variables against template

**PlaygroundExecutor**
- Handles AI provider communication (Anthropic, OpenAI)
- Manages API keys from Rails credentials
- Formats requests and parses responses

### Testing Philosophy

Read `.ai/RSPEC-TESTS.md` before writing tests. Key principles:
- Use request specs instead of controller specs
- Test full request/response cycle
- Use FactoryBot for test data
- Keep unit tests focused on single behaviors
- Test both happy and unhappy paths

### CSS Architecture

- BEM methodology with `.component__element--modifier` pattern
- Foundation based on shadcn/ui aesthetic
- Propshaft for asset management
- Components organized in separate files (buttons, forms, tables, etc.)
- All styles must be explicitly imported in `application.css`

## Key Implementation Details

### Version Control System
- Automatic versioning tracks changes to content, system_message, and model settings
- Version history preserved with change descriptions
- One-click restore to any previous version
- Counter cache for efficient version counting

### Variable System
- Variables use `{{variable_name}}` syntax
- Automatic parameter detection and synchronization
- Type inference based on naming conventions
- Support for complex types (arrays, JSON)

### Playground Feature
- Live testing with real AI providers
- Supports multiple models (GPT-4, Claude, etc.)
- Real-time execution with streaming responses
- Token counting and cost estimation

### Engine Integration
The engine is designed to be mounted in Rails applications:
```ruby
# Host app's routes.rb
mount ActivePrompt::Engine => "/active_prompt"

# Usage in application
ActivePrompt.render(:prompt_name, variables: { user_name: "John" })
```

## Current Status

**Implemented**: Core CRUD, version control, parameter management, playground, admin UI

**In Progress**: Analytics dashboard, evaluation suite, API endpoints

**Planned**: Multi-language support, A/B testing, prompt marketplace

See `docs/SPEC.md` for complete product vision and `docs/ARCHITECTURE.md` for detailed technical documentation.
