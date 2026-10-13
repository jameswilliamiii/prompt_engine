# Changelog

All notable changes to PromptEngine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-10-12

### Added
- Effort setting on prompts, versioned like temperature and settable per render with `options: { effort: }`. Sent as Anthropic's `output_config: { effort: }` to models flagged `supports_effort: true`.
- Model families: PromptEngine resolves a model's provider, `supports_temperature` and `supports_effort` from its name (`DEFAULT_MODEL_FAMILIES`, overridable with `config.model_families`), so newly released Claude and GPT models work without a config change. Catalog entries override the family settings key by key.
- `config.models` accepts a callable, so the model list can come from ruby_llm's registry.
- `supports_temperature` and `supports_effort` flags on model catalog entries. The prompt form shows each field only for models that accept it, and clears a field when you switch to a model that doesn't. The prompt page marks a stored setting the model doesn't use.
- `RenderedPrompt#to_ruby_llm_chat`, which returns a ready RubyLLM chat with the system message and settings applied.
- `bin/rails generate prompt_engine:upgrade`, which copies new migrations and lists the steps for the version. See `UPGRADING.md`.

### Changed
- Requires `ruby_llm ~> 1.16`.
- Default model catalog lists Claude Opus 5.5, Sonnet 5.5 and Haiku 5.5 in place of the 4.x models, with labels only; families supply the rest.
- `execute_with` takes the `RubyLLM` module or a `RubyLLM::Context` and returns the reply. It no longer accepts Anthropic SDK clients.
- `to_ruby_llm_params` and `to_openai_params` leave out `model` when a prompt has none, instead of sending `"gpt-4"`.
- `to_openai_params` and `to_ruby_llm_params` send `max_completion_tokens` instead of `max_tokens` for models whose catalog provider is `"openai"`.
- `PromptEngine.render` passes variables and options separately, so a template variable named like an option still renders as a variable.
- Evaluations start only for a prompt whose model resolves to provider `"openai"`. The runner no longer falls back to `"gpt-4"`.
- ruby_llm loads when first used rather than when PromptEngine loads.

### Fixed
- The playground sends the prompt's `max_tokens`, and reaches models newer than ruby_llm's bundled registry.
- The playground records the settings it actually sent with each run.
- Editing a prompt whose model isn't in the catalog keeps that model instead of blanking it.
- The playground sets API keys on a scoped RubyLLM context instead of replacing the host app's global keys.
- The playground reports a refusal or a `max_tokens` cutoff instead of saving an empty response as a success.
- The playground shows the provider's error message for a rejected request, and recognizes ruby_llm's authentication, rate limit and overload errors.
- Restoring a version from the versions page restores its effort, and run comparisons show effort.
- The usage example on the prompt page passes variables as a hash, so it runs as written.
- The `prompt_engine:eval_demo` task referenced classes from the gem's old name.

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