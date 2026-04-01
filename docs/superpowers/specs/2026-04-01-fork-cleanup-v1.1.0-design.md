# Fork Cleanup & v1.1.0 Release Design

**Date:** 2026-04-01  
**Status:** Approved

## Overview

This gem was forked from [aviflombaum/prompt_engine](https://github.com/aviflombaum/prompt_engine) and has had significant development since the 1.0.0 release. This cleanup prepares a proper 1.1.0 release under the fork, updating metadata, removing stale attribution, and producing an accurate changelog.

---

## 1. gemspec (`prompt_engine.gemspec`)

**Authors** — Add James Stubblefield as co-author alongside Avi Flombaum. Both `authors` and `email` become arrays.

**URIs** — Update URI fields to point to the fork:
- `spec.homepage` → `https://github.com/jameswilliamiii/prompt_engine`
- `spec.metadata["homepage_uri"]` → `https://github.com/jameswilliamiii/prompt_engine`
- `spec.metadata["source_code_uri"]` → `https://github.com/jameswilliamiii/prompt_engine`
- `spec.metadata["changelog_uri"]` → `https://github.com/jameswilliamiii/prompt_engine/blob/main/CHANGELOG.md`

**sqlite3 dependency** — Move from `add_dependency` (runtime) to `add_development_dependency`. The engine never references sqlite3 directly; it is only used by the dummy app for dev/test. Host applications manage their own DB adapter.

**csv dependency** — Keep as `add_dependency` (runtime). The `csv` stdlib gem is required inline in `test_cases_controller.rb` for parsing CSV file uploads (part of the eval feature). Even though the eval nav link is hidden, the routes and controller are live and functional, so `csv` remains a runtime dependency.

---

## 2. README (`README.md`)

**Remove:**
- "Made with ❤️ by Avi.nyc" and "Sponsored by Innovent Capital" badges
- "WARNING - IN ACTIVE DEVELOPMENT" section
- "Documentation and Demo" section (links to Avi's demo/docs sites)
- Sponsors section (Innovent Capital)
- "Built with ❤️ by Avi.nyc" footer line
- Support section links pointing to Avi's email, demo, and docs sites
- Live Demo and Documentation links in the Support section

**Add:**
- Fork attribution line near the top, directly below the tagline: "This is a fork of [aviflombaum/prompt_engine](https://github.com/aviflombaum/prompt_engine) by Avi Flombaum."

**Update:**
- Issue Tracker link → `https://github.com/jameswilliamiii/prompt_engine/issues`
- Discussions link → `https://github.com/jameswilliamiii/prompt_engine/discussions`
- Support section: keep only Issue Tracker and Discussions links (pointing to the fork); remove Avi's email and demo/docs links; remove the Live Demo and Documentation entries

---

## 3. Version (`lib/prompt_engine/version.rb`)

Bump `VERSION` from `"1.0.0"` to `"1.1.0"`.

---

## 4. Changelog (`CHANGELOG.md`)

Convert `[Unreleased]` to `[1.1.0] - 2026-04-01` and fill in all changes since 1.0.0:

**Added:**
- Authentication system (HTTP Basic, Devise route-level, custom via ActiveSupport hooks, Rack middleware)
- `PromptEngine.configure` block with environment-specific auth configuration; authentication enabled by default
- Settings UI for managing API keys per provider (OpenAI, Anthropic) without using Rails credentials
- Comprehensive dashboard with prompt statistics and recent activity
- Playground run history — save and review past test runs
- Configurable model catalog via `PromptEngine::Configuration#models` — host apps inject their own model list via `PromptEngine.configure`
- Per-model playground — model dropdown pre-selected to the prompt's configured model; API key field swaps based on derived provider
- Full authentication test suite

**Changed:**
- `PlaygroundExecutor` now derives provider from the configured model catalog instead of a hardcoded map; accepts `model:` instead of `provider:`
- Prompt form model select renders from `PromptEngine.config.models`
- Updated RubyLLM dependency to 1.6.4
- Sidebar layout reorganized: Back to Admin at top, version and GitHub link in footer
- Removed "Made with love" and sponsorship attributions from admin UI

**Fixed:**
- Flash messages not displaying correctly
- Incorrect status being set on rendered prompts
- Test run items having no horizontal padding on dashboard

**Security:**
- Uses `ActiveSupport::SecurityUtils.secure_compare` for credential comparison to prevent timing attacks
- Credentials never logged or exposed in error messages
- Authentication enabled by default; must be explicitly disabled

---

## 5. CLAUDE.md

Prepend a **"Fork Status & Key Context"** section at the top of the existing `CLAUDE.md` (before the current "PromptEngine Rails Engine" heading). All existing content remains intact. The new section should cover:

- Fork origin: forked from `aviflombaum/prompt_engine`; maintained at `jameswilliamiii/prompt_engine`
- Current version: 1.1.0
- Eval system: fully built (models, controllers, routes, views) but nav link hidden via ERB/HTML comments; routes still live at `/prompt_engine/evaluations`; intentionally excluded from 1.1.0; candidate for a future release
- Configurable model catalog: `PromptEngine::Configuration` defined in `lib/prompt_engine.rb`; host apps configure via `PromptEngine.configure { |c| c.models = { "model-id" => { provider: "openai", label: "..." } } }`; defaults include common GPT-4 and Claude models
- Settings model: `PromptEngine::Setting` stores API keys per provider; `PlaygroundExecutor` reads from settings first, falls back to Rails credentials
- Authentication: flexible system; no built-in auth UI — host apps configure via route constraints, Rack middleware, or ActiveSupport hooks; authentication is on by default

---

## Out of Scope

- Eval system: exists but hidden from nav; leave as-is; no changelog entry
- Eval nav cleanup (messy HTML/ERB comments): separate task
- Any feature additions or refactors beyond the above
