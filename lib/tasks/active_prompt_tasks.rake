# desc "Explaining what the task does"
# task :active_prompt do
#   # Task goes here
# end

namespace :active_prompt do
  desc "Setup dummy app for development and testing"
  task setup: :environment do
    puts "Setting up ActivePrompt dummy app..."

    dummy_root = File.expand_path("../../spec/dummy", __dir__)

    Dir.chdir(dummy_root) do
      # Remove existing migrations and schema
      FileUtils.rm_rf(Dir.glob("db/migrate/*"))
      FileUtils.rm_f("db/schema.rb")
      FileUtils.rm_f("db/development.sqlite3")
      FileUtils.rm_f("db/test.sqlite3")

      # Install engine migrations
      system("bundle exec rails active_prompt:install:migrations")

      # Create and migrate databases
      system("bundle exec rails db:create")
      system("bundle exec rails db:migrate")
      system("RAILS_ENV=test bundle exec rails db:create")
      system("RAILS_ENV=test bundle exec rails db:migrate")

      puts "✅ ActivePrompt dummy app setup complete!"
    end
  end
end
