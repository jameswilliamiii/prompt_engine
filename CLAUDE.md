# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## ActivePrompt Rails Engine

ActivePrompt is a mountable Rails engine for AI prompt management. It provides a centralized admin
interface where teams can create, version, test, and optimize their AI prompts without deploying
code changes.

## Development Rules and Conventions

Read the files in .ai/ to understand the best practices and conventions to use when coding.

- `.ai/RSPEC-TESTS.md` should be read before writing tests.

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
bundle exec rspec                    # Run all tests
bundle exec rspec spec/models        # Run model tests
bundle exec rspec spec/system        # Run system tests
bundle exec rspec path/to/spec.rb   # Run specific test file
```

### Asset Management

The engine uses Propshaft (Rails 8 default). CSS files must be explicitly imported in
`app/assets/stylesheets/active_prompt/application.css`:

```css
@import url("foundation.css");
@import url("layout.css");
/* etc... */
```

### Installing Engine Migrations in Host App

```bash
bin/rails active_prompt:install:migrations
```

## Architecture Overview

### Engine Structure

- **Isolated namespace**: All models, controllers, and views are under `ActivePrompt` module
- **Table prefix**: Database tables use `active_prompt_` prefix (e.g., `active_prompt_prompts`)
- **Asset organization**: BEM methodology for CSS, organized by component

### Key Models

- `ActivePrompt::Prompt`: Core model with fields for name, content, system_message, model settings
  (temperature, max_tokens), and status enum (draft/active/archived)

### Controller Organization

- `ApplicationController`: Base controller for engine
- `PromptsController`: Main CRUD controller, uses admin layout
- Routes are flat (no admin namespace in URLs): `/active_prompt/prompts/1`

### CSS Architecture

- **Foundation**: Color variables, typography, spacing system
- **Components**: Separate files for buttons, forms, tables, cards, sidebar
- **Overrides**: Ensures proper styling inheritance (fixes link colors in dark contexts)
- **BEM naming**: `.component__element--modifier` pattern throughout

### Testing Setup

- RSpec configured with dummy app in `spec/dummy`
- FactoryBot for test data generation
- Migration paths configured for both engine and dummy app

### Current Implementation Status

**Completed**:

- Full CRUD for prompts
- Admin UI with sidebar navigation
- Responsive table/form layouts
- Status management (draft/active/archived)
- Flash notifications
- CSS foundation matching shadcn/ui aesthetic

**Planned Features** (from SPEC.md):

- Version control for prompts
- Testing playground with live AI execution
- Parameter detection from prompt templates ({{variable}})
- Analytics and usage tracking
- API endpoints for prompt rendering
- Evaluation suite for prompt testing

### Integration Points

The engine is designed to be mounted in a host Rails application:

```ruby
# Host app's routes.rb
mount ActivePrompt::Engine => "/active_prompt"
```

Future integration will provide:

```ruby
ActivePrompt.render(:prompt_name, variables: {})
```
