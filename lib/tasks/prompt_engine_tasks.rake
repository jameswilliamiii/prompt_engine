# desc "Explaining what the task does"
# task :prompt_engine do
#   # Task goes here
# end

namespace :prompt_engine do
  desc "Setup dummy app for development and testing"
  task setup: :environment do
    gem_root = File.expand_path("../..", __dir__)
    app_root = Rails.root.to_s

    unless app_root.start_with?(gem_root)
      abort "❌ This task can only be run from within the PromptEngine gem development environment."
    end

    unless Rails.env.development?
      abort "❌ This task can only be run in the development environment."
    end

    puts "Setting up PromptEngine dummy app..."

    dummy_root = File.expand_path("../../spec/dummy", __dir__)

    Dir.chdir(dummy_root) do
      # Remove existing migrations and schema
      FileUtils.rm_rf(Dir.glob("db/migrate/*"))
      FileUtils.rm_f("db/schema.rb")

      # Drop databases if they exist
      system("bundle exec rails db:drop", exception: false)
      system("RAILS_ENV=test bundle exec rails db:drop", exception: false)

      # Install engine migrations
      system("bundle exec rails prompt_engine:install:migrations")

      # Create and migrate databases
      system("bundle exec rails db:create")
      system("bundle exec rails db:migrate")
      system("bundle exec rails db:seed")
      system("RAILS_ENV=test bundle exec rails db:create")
      system("RAILS_ENV=test bundle exec rails db:migrate")

      puts "✅ PromptEngine dummy app setup complete!"
    end
  end
end
