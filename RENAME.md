# PromptEngine to PromptEngine Migration Plan

## Overview

This document outlines the comprehensive plan for renaming the `prompt_engine` gem to
`prompt_engine`. This gem has not been published yet and is not in use so there is no worry about
user migration or backward compatibility.

## Migration Strategy

### Phase 1: Preparation (Pre-Release)

### Phase 2: Core Renaming (Development)

### Phase 3: Testing & Validation

---

## Phase 1: Preparation

### 1.1 Create Migration Branch

We are already on a migration branch

### 1.2 Update Version Strategy

- Current version: `0.1.0`
- New version: `1.0.0` (major version bump for breaking changes)
- Update `lib/prompt_engine/version.rb`:

```ruby
module PromptEngine
  VERSION = "1.0.0"
end
```

### 1.3 Create Migration Documentation

- Update README with migration instructions
- Create UPGRADE.md with detailed migration steps
- Update all documentation files

---

## Phase 2: Core Renaming

### 2.1 Directory Structure Renaming

#### 2.1.1 Rename Core Directories

```bash
# Core gem structure
mv lib/prompt_engine lib/prompt_engine
mv app/controllers/prompt_engine app/controllers/prompt_engine
mv app/models/prompt_engine app/models/prompt_engine
mv app/views/prompt_engine app/views/prompt_engine
mv app/services/prompt_engine app/services/prompt_engine
mv app/clients/prompt_engine app/clients/prompt_engine
mv app/helpers/prompt_engine app/helpers/prompt_engine
mv app/jobs/prompt_engine app/jobs/prompt_engine
mv app/mailers/prompt_engine app/mailers/prompt_engine

# Assets
mv app/assets/stylesheets/prompt_engine app/assets/stylesheets/prompt_engine
mv app/assets/images/prompt_engine app/assets/images/prompt_engine

# Tests
mv spec/controllers/prompt_engine spec/controllers/prompt_engine
mv spec/requests/prompt_engine spec/requests/prompt_engine
mv spec/services/prompt_engine spec/services/prompt_engine
mv spec/system/prompt_engine spec/system/prompt_engine
mv spec/models/prompt_engine spec/models/prompt_engine

# Layouts
mv app/views/layouts/prompt_engine app/views/layouts/prompt_engine
```

#### 2.1.2 Rename Core Files

```bash
# Gem specification
mv prompt_engine.gemspec prompt_engine.gemspec

# Main library file
mv lib/prompt_engine.rb lib/prompt_engine.rb
mv lib/prompt_engine/engine.rb lib/prompt_engine/engine.rb
mv lib/prompt_engine/version.rb lib/prompt_engine/version.rb
```

### 2.2 Module Namespace Updates

#### 2.2.1 Update All Ruby Files

**Global find and replace:**

- `module PromptEngine` → `module PromptEngine`
- `PromptEngine::` → `PromptEngine::`

**Files requiring manual updates:**

- `lib/prompt_engine.rb`
- `lib/prompt_engine/engine.rb`
- `lib/prompt_engine/version.rb`
- All files in `app/models/prompt_engine/`
- All files in `app/controllers/prompt_engine/`
- All files in `app/services/prompt_engine/`
- All files in `app/clients/prompt_engine/`
- All files in `app/helpers/prompt_engine/`
- All files in `app/jobs/prompt_engine/`
- All files in `app/mailers/prompt_engine/`

#### 2.2.2 Update Model Table Names

**Update all model files with new table names:**

```ruby
# app/models/prompt_engine/prompt.rb
module PromptEngine
  class Prompt < ApplicationRecord
    self.table_name = "prompt_engine_prompts"
    # ... rest of the model
  end
end

# app/models/prompt_engine/prompt_version.rb
module PromptEngine
  class PromptVersion < ApplicationRecord
    self.table_name = "prompt_engine_prompt_versions"
    # ... rest of the model
  end
end

# app/models/prompt_engine/parameter.rb
module PromptEngine
  class Parameter < ApplicationRecord
    self.table_name = "prompt_engine_parameters"
    # ... rest of the model
  end
end

# app/models/prompt_engine/setting.rb
module PromptEngine
  class Setting < ApplicationRecord
    self.table_name = "prompt_engine_settings"
    # ... rest of the model
  end
end

# app/models/prompt_engine/playground_run_result.rb
module PromptEngine
  class PlaygroundRunResult < ApplicationRecord
    self.table_name = "prompt_engine_playground_run_results"
    # ... rest of the model
  end
end

# app/models/prompt_engine/eval_set.rb
module PromptEngine
  class EvalSet < ApplicationRecord
    self.table_name = "prompt_engine_eval_sets"
    # ... rest of the model
  end
end

# app/models/prompt_engine/eval_run.rb
module PromptEngine
  class EvalRun < ApplicationRecord
    self.table_name = "prompt_engine_eval_runs"
    # ... rest of the model
  end
end

# app/models/prompt_engine/eval_result.rb
module PromptEngine
  class EvalResult < ApplicationRecord
    self.table_name = "prompt_engine_eval_results"
    # ... rest of the model
  end
end

# app/models/prompt_engine/test_case.rb
module PromptEngine
  class TestCase < ApplicationRecord
    self.table_name = "prompt_engine_test_cases"
    # ... rest of the model
  end
end
```

### 2.3 Database Migration Strategy

Instead of creating a new migration to rename the table, let's edit the existing migrations to
reflect the name change because this gem hasn't been released yet and we can drop all tables now and
just re-run the entire migrations (including dropping the schema or whatever else we need).

### 2.4 Routes and URLs

#### 2.4.1 Update Engine Routes

**Update `config/routes.rb`:**

```ruby
PromptEngine::Engine.routes.draw do
  # ... existing routes remain the same
end
```

#### 2.4.2 Update Mounting Configuration

**Update `spec/dummy/config/routes.rb`:**

```ruby
Rails.application.routes.draw do
  mount PromptEngine::Engine => "/prompt_engine"
  root to: redirect("/prompt_engine")
end
```

#### 2.4.3 Update All URL References

**Global find and replace:**

- `/prompt_engine/` → `/prompt_engine/`
- `prompt_engine.prompts_path` → `prompt_engine.prompts_path`
- `prompt_engine.prompt_path` → `prompt_engine.prompt_path`
- etc.

### 2.5 Asset References

#### 2.5.1 Update Layout Files

**Update `app/views/layouts/prompt_engine/application.html.erb`:**

```erb
<%= stylesheet_link_tag "prompt_engine/application", media: "all" %>
```

**Update `app/views/layouts/prompt_engine/admin.html.erb`:**

```erb
<%= stylesheet_link_tag "prompt_engine/application", "data-turbo-track": "reload" %>
```

#### 2.5.2 Update View References

**Update all view files that reference assets:**

- `app/views/prompt_engine/shared/_form_errors.html.erb`
- Any other views with asset references

### 2.6 Gem Specification Updates

#### 2.6.1 Update `prompt_engine.gemspec`

```ruby
require_relative "lib/prompt_engine/version"

Gem::Specification.new do |spec|
  spec.name = "prompt_engine"
  spec.version = PromptEngine::VERSION
  spec.authors = [ "Avi Flombaum" ]
  spec.email = [ "4515+aviflombaum@users.noreply.github.com" ]
  spec.homepage = "https://github.com/aviflombaum/prompt_engine"
  spec.summary = "Rails mountable engine for AI prompt management"
  spec.description = "PromptEngine is a Rails mountable engine that provides a simple interface for managing AI prompts, templates, and responses within Rails applications."
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aviflombaum/prompt_engine"
  spec.metadata["changelog_uri"] = "https://github.com/aviflombaum/prompt_engine/blob/main/CHANGELOG.md"

  # ... rest of the specification
end
```

### 2.7 Test Infrastructure Updates

#### 2.7.1 Update Factory References

**Update all factory files:**

```ruby
# spec/factories/prompts.rb
factory :prompt, class: 'PromptEngine::Prompt' do
  # ... factory definition
end

# spec/factories/prompt_versions.rb
factory :prompt_version, class: 'PromptEngine::PromptVersion' do
  # ... factory definition
end

# Continue for all other factories...
```

#### 2.7.2 Update Test Route Helpers

**Update all test files:**

```ruby
# spec/requests/prompt_engine/prompts_spec.rb
module PromptEngine
  RSpec.describe "Prompts", type: :request do
    include PromptEngine::Engine.routes.url_helpers

    # Update all route helper calls
    # prompt_engine.prompts_path → prompt_engine.prompts_path
  end
end
```

#### 2.7.3 Update Test URLs

**Update all hardcoded URLs in tests:**

- `/prompt_engine/prompts` → `/prompt_engine/prompts`
- `/prompt_engine/settings` → `/prompt_engine/settings`
- etc.

### 2.8 Documentation Updates

#### 2.8.1 Update README.md

````markdown
# PromptEngine

A Rails engine for managing AI prompts with version control and secure API key storage.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "prompt_engine"
```
````

And then execute:

```bash
$ bundle
$ rails prompt_engine:install:migrations
$ rails db:migrate
```

## Setup

### Mount the Engine

In your `config/routes.rb`:

```ruby
mount PromptEngine::Engine => "/prompt_engine"
```

## Usage

Visit `/prompt_engine` to access the admin interface.

````

#### 2.8.2 Update All Documentation Files
- `docs/API_CREDENTIALS.md`
- `docs/ARCHITECTURE.md`
- `docs/USAGE.md`
- `docs/SPEC.md`
- All files in `tasks/` directory
- All markdown files with examples

---

## Phase 3: Testing & Validation

### 3.1 Automated Testing
```bash
# Run all tests to ensure functionality
bundle exec rspec

# Run specific test suites
bundle exec rspec spec/models/prompt_engine/
bundle exec rspec spec/requests/prompt_engine/
bundle exec rspec spec/services/prompt_engine/
bundle exec rspec spec/system/
````

### 3.2 Manual Testing Checklist

- [ ] Engine mounts correctly at `/prompt_engine`
- [ ] All CRUD operations work for prompts
- [ ] Version management works
- [ ] Playground functionality works
- [ ] Evaluation system works
- [ ] Settings management works
- [ ] All assets load correctly
- [ ] All routes work correctly
- [ ] Database migrations work
- [ ] API endpoints work

### 3.3 Integration Testing

- [ ] Test with dummy application
- [ ] Test database migrations
- [ ] Test asset compilation
- [ ] Test route mounting
- [ ] Test API integration

---

## Phase 4: Release & Migration Support

### 4.1 Pre-Release Checklist

- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Migration scripts are tested
- [ ] Breaking changes are documented
- [ ] Version is bumped to 1.0.0

### 4.2 Release Process

1. Create release branch
2. Update version to 1.0.0
3. Update CHANGELOG.md with breaking changes
4. Create git tag
5. Push to RubyGems
6. Update GitHub repository

### 4.3 User Migration Support

#### 4.3.1 Create UPGRADE.md

````markdown
# Upgrading from PromptEngine to PromptEngine

## Breaking Changes

This is a major version upgrade with breaking changes:

### Gem Name Change

- Old: `gem "prompt_engine"`
- New: `gem "prompt_engine"`

### Route Change

- Old: `mount PromptEngine::Engine => "/prompt_engine"`
- New: `mount PromptEngine::Engine => "/prompt_engine"`

### Database Changes

- All tables are renamed with `prompt_engine_` prefix
- Run migrations to rename tables

## Migration Steps

1. Update Gemfile:
   ```ruby
   gem "prompt_engine", "~> 1.0"
   ```
````

2. Update routes:

   ```ruby
   mount PromptEngine::Engine => "/prompt_engine"
   ```

3. Run migrations:

   ```bash
   bundle install
   rails prompt_engine:install:migrations
   rails db:migrate
   ```

4. Update any hardcoded URLs:

   - `/prompt_engine/` → `/prompt_engine/`

5. Update any API integrations:
   - `PromptEngine::` → `PromptEngine::`

## Success Criteria

### Technical Success

- [ ] All tests pass
- [ ] No breaking functionality
- [ ] Database migrations work correctly
- [ ] Assets load properly
- [ ] Routes work correctly
