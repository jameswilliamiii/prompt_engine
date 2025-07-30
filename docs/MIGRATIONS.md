# PromptEngine Migration Guide

## Overview

PromptEngine requires explicit migration installation. The engine does NOT automatically load migrations at runtime. This gives host applications full control over when migrations are added to their codebase.

## Development Setup (Dummy App)

When developing the engine or running tests:

```bash
bundle exec rake setup
```

This command:
1. Drops existing databases
2. Clears existing migrations  
3. Installs engine migrations into the dummy app using `rails prompt_engine:install:migrations`
4. Creates and migrates both development and test databases
5. Seeds development database with sample data

## Production Setup (Host Application)

When installing PromptEngine in a Rails application:

### Required: Install Migrations

```bash
# IMPORTANT: You must run this before db:migrate
bundle exec rails prompt_engine:install:migrations
bundle exec rails db:migrate
```

This copies migrations to your app's `db/migrate` folder with timestamps and `.prompt_engine.rb` suffix.

**Note**: Unlike many Rails engines, PromptEngine does NOT automatically include its migrations. You must explicitly install them using the command above.

## Troubleshooting

### Error: "relation does not exist"

If you get errors about missing tables when running `rails db:migrate`:
- You forgot to run `rails prompt_engine:install:migrations` first
- Run the install command, then migrate again

### Duplicate Migration Errors

If you encounter duplicate migration errors:
- Check your `db/migrate` folder for duplicate `.prompt_engine.rb` files
- Remove any duplicates and run `rails db:migrate:status` to check migration state

## Technical Details

The engine's automatic migration loading is intentionally disabled in `lib/prompt_engine/engine.rb`:

```ruby
# IMPORTANT: Migrations are NOT automatically loaded!
# Users must explicitly install migrations using:
#   bin/rails prompt_engine:install:migrations
#
# This ensures host applications have full control over when
# engine migrations are added to their codebase.
```

This design choice ensures:
- No surprise migrations when updating the gem
- Clear visibility of what database changes are being made
- Better control over migration timing in production deployments