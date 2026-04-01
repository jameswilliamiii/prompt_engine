# Changelog

All notable changes to PromptEngine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-04-01

### Added
- Authentication system with multiple strategies:
  - HTTP Basic authentication with secure credential comparison
  - Route-level integration with host app authentication (Devise, custom auth)
  - ActiveSupport hooks for custom authentication logic (`ActiveSupport.on_load(:prompt_engine_application_controller)`)
  - Rack middleware support for advanced scenarios
- `PromptEngine.configure` block for authentication and engine configuration; authentication enabled by default
- Settings UI for managing API keys per provider (OpenAI, Anthropic) without requiring Rails credentials
- Comprehensive dashboard with prompt statistics and recent activity
- Playground run history — save and review past test runs
- Configurable model catalog via `PromptEngine::Configuration#models` — host apps inject their own model list via `PromptEngine.configure { |c| c.models = {...} }`
- Configurable back-link via `PromptEngine::Configuration#back_path` and `#back_label` — host apps set the destination URL and link text; defaults to `root_path` and "← Back" if not configured
- Per-model playground — model dropdown pre-selected to the prompt's configured model; API key field swaps dynamically based on derived provider
- Full authentication test suite

### Changed
- `PlaygroundExecutor` now derives provider from the configured model catalog instead of a hardcoded map; accepts `model:` keyword argument instead of `provider:`
- Prompt form model select renders from `PromptEngine.config.models`
- Updated RubyLLM dependency to 1.6.4
- Sidebar layout reorganized: back link at top with divider; version and GitHub link moved to footer
- Removed "Made with love" and sponsorship attributions from admin UI footer

### Fixed
- Flash messages not displaying correctly
- Incorrect status being set on rendered prompts
- Test run items having no horizontal padding on the dashboard

### Security
- Uses `ActiveSupport::SecurityUtils.secure_compare` for credential comparison to prevent timing attacks
- Credentials never logged or exposed in error messages
- Authentication enabled by default; must be explicitly disabled for development environments

## [1.0.0] - 2025-01-24

### Added
- Initial release of PromptEngine
- Core prompt management functionality
  - Create, edit, and organize prompts with slug-based identification
  - Automatic variable detection with `{{variable}}` syntax
  - Version control with automatic versioning and rollback
  - Parameter type detection and validation
- Admin interface
  - Modern, responsive UI design
  - Prompt playground for testing with real AI providers
  - Version comparison and history
  - Status management (draft, active, archived)
- AI Provider Integration
  - Support for OpenAI and Anthropic
  - Configurable model settings (temperature, max_tokens, etc.)
  - Secure API key storage using Rails encryption
- Developer API
  - Simple integration: `PromptEngine.render(:prompt_slug, variables: {})`
  - Direct LLM integration support
  - Override model settings at runtime
- Testing Infrastructure
  - RSpec test suite
  - VCR for API testing
  - Factory Bot for test data
- Documentation
  - Comprehensive README
  - Architecture documentation
  - API usage examples