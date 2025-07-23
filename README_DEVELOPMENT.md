# ActivePrompt Development Setup

## Initial Setup

After cloning the repository, run the setup task to initialize both development and test databases:

```bash
bundle install
bundle exec rake setup
```

This will:
1. Install engine migrations into the dummy app
2. Create and migrate both development and test databases
3. Seed the development database with sample data

## Running Tests

```bash
bundle exec rspec
```

## Running the Development Server

```bash
cd spec/dummy && rails s
```

Then visit http://localhost:3000/active_prompt

## Manual Database Setup (if needed)

If you prefer to set up databases manually:

```bash
# Install migrations
cd spec/dummy
bundle exec rails active_prompt:install:migrations

# Development database
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed

# Test database
RAILS_ENV=test bundle exec rails db:create
RAILS_ENV=test bundle exec rails db:migrate
```

## Why Manual Setup?

ActivePrompt follows the Rails engine convention of requiring explicit setup. This is the same pattern used by popular engines like Devise, Solidus, and Administrate. Benefits include:

- Clear, reproducible setup steps
- No performance overhead during development
- Better CI/CD compatibility
- Avoiding Rails initialization issues