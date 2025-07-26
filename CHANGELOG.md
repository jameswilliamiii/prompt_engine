# Changelog

All notable changes to PromptEngine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Flexible authentication system with multiple strategies
  - HTTP Basic authentication with secure credential comparison
  - Integration with host app authentication (Devise, custom auth)
  - ActiveSupport hooks for custom authentication logic
  - Rack middleware support for advanced scenarios
- Configuration API for authentication settings
  - `PromptEngine.configure` block for easy setup
  - Environment-specific authentication configuration
  - Ability to disable authentication for development
- Comprehensive authentication documentation
  - Detailed setup guide in README
  - Dedicated AUTHENTICATION.md with examples and best practices
  - Security recommendations and troubleshooting tips
- Authentication test suite with full coverage

### Security
- Uses `ActiveSupport::SecurityUtils.secure_compare` to prevent timing attacks
- Credentials are never logged or exposed in error messages
- Authentication is enabled by default (must be explicitly disabled)

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