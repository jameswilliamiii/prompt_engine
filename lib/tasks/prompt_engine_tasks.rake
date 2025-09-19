# desc "Explaining what the task does"
# task :prompt_engine do
#   # Task goes here
# end

namespace :prompt_engine do
  desc "Setup dummy app for development and testing"
  task setup: :environment do
    puts "Setting up PromptEngine dummy app..."

    dummy_root = File.expand_path("../../spec/dummy", __dir__)

    Dir.chdir(dummy_root) do
      # Remove existing migrations and schema
      FileUtils.rm_rf(Dir.glob("db/migrate/*"))
      FileUtils.rm_f("db/schema.rb")
      FileUtils.rm_f("db/development.sqlite3")
      FileUtils.rm_f("db/test.sqlite3")

      # Install engine migrations
      system("bundle exec rails prompt_engine:install:migrations")

      # Create and migrate databases
      system("bundle exec rails db:create")
      system("bundle exec rails db:migrate")
      system("RAILS_ENV=test bundle exec rails db:create")
      system("RAILS_ENV=test bundle exec rails db:migrate")

      puts "✅ PromptEngine dummy app setup complete!"
    end
  end

 desc "Build assets for gem packaging"
  task :build_assets do
    puts "Building PromptEngine assets..."

    # Ensure the builds directory exists
    builds_dir = File.expand_path("../../app/assets/builds", __dir__)
    FileUtils.mkdir_p(builds_dir)

    # Change to dummy app directory for asset compilation
    dummy_dir = File.expand_path("../../spec/dummy", __dir__)

    Dir.chdir(dummy_dir) do
      # Clean first to ensure fresh build
      system("bundle exec rails assets:clobber") if Dir.exist?("tmp")

      # Ensure proper asset configuration for compilation
      puts "Configuring assets for compilation..."
      
      # Precompile assets with debug off to ensure concatenation
      puts "Precompiling assets..."
      success = system("RAILS_ENV=production bundle exec rails assets:precompile")
      
      unless success
        puts "❌ Asset precompilation failed"
        exit 1
      end

      # Find compiled CSS
      compiled_patterns = [
        "public/assets/prompt_engine/application-*.css",
        "public/assets/prompt_engine/application.css"
      ]

      compiled_file = nil
      compiled_patterns.each do |pattern|
        files = Dir.glob(pattern)
        if files.any?
          compiled_file = files.max_by { |f| File.mtime(f) }
          break
        end
      end

      if compiled_file && File.exist?(compiled_file)
        target_file = File.join(builds_dir, "application.css")
        FileUtils.cp(compiled_file, target_file)
        
        # Verify the content is properly concatenated
        content = File.read(target_file)
        
        if content.include?("*= require") || content.size < 10000
          puts "⚠ WARNING: Compiled CSS contains Sprockets directives or is too small"
          puts "This suggests the asset pipeline isn't concatenating files properly"
          puts "File size: #{content.size} bytes"
          
          # Try to manually concatenate if needed
          puts "Attempting manual concatenation..."
          manual_concatenate_css(builds_dir)
        else
          file_size = File.size(target_file)
          puts "✓ Copied compiled CSS to app/assets/builds/ (#{file_size} bytes)"
          
          # Show preview
          puts "Content preview (first 200 chars):"
          puts content[0..200]
        end
      else
        puts "❌ No compiled CSS found"
        puts "Available files in public/assets:"
        Dir.glob("public/assets/**/*.css").each { |f| puts "  #{f}" }
        exit 1
      end

      # Clean up
      system("bundle exec rails assets:clobber") if Dir.exist?("tmp")
    end

    puts "✅ Asset build complete"
  end

  private

  def self.manual_concatenate_css(builds_dir)
    engine_root = File.expand_path("../..", __dir__)
    css_files = [
      "app/assets/stylesheets/prompt_engine/foundation.css",
      "app/assets/stylesheets/prompt_engine/layout.css",
      "app/assets/stylesheets/prompt_engine/sidebar.css",
      "app/assets/stylesheets/prompt_engine/buttons.css",
      "app/assets/stylesheets/prompt_engine/forms.css",
      "app/assets/stylesheets/prompt_engine/tables.css",
      "app/assets/stylesheets/prompt_engine/cards.css",
      "app/assets/stylesheets/prompt_engine/dashboard.css",
      "app/assets/stylesheets/prompt_engine/prompts.css",
      "app/assets/stylesheets/prompt_engine/versions.css",
      "app/assets/stylesheets/prompt_engine/notifications.css",
      "app/assets/stylesheets/prompt_engine/loading.css",
      "app/assets/stylesheets/prompt_engine/comparison.css",
      "app/assets/stylesheets/prompt_engine/evaluations.css",
      "app/assets/stylesheets/prompt_engine/workflows.css",
      "app/assets/stylesheets/prompt_engine/utilities.css",
      "app/assets/stylesheets/prompt_engine/overrides.css",
      "app/assets/stylesheets/prompt_engine/components/_test_runs.css"
    ]

    concatenated_css = "/* PromptEngine - Concatenated CSS */\n\n"
    
    # Add CSS variables first
    concatenated_css += <<~CSS
      :root {
        --color-primary: #3b82f6;
        --color-gray-50: #f9fafb;
        --color-gray-100: #f3f4f6;
        --color-gray-200: #e5e7eb;
        --color-gray-400: #9ca3af;
        --color-gray-600: #4b5563;
        --color-gray-700: #374151;
        --color-gray-900: #111827;
        --font-mono: ui-monospace, SFMono-Regular, "SF Mono", Monaco, Inconsolata, "Liberation Mono", "Consolas", monospace;
      }

    CSS

    css_files.each do |file_path|
      full_path = File.join(engine_root, file_path)
      if File.exist?(full_path)
        content = File.read(full_path)
        # Remove any @import statements
        content = content.gsub(/@import.*?;/, '')
        concatenated_css += "/* #{File.basename(file_path)} */\n"
        concatenated_css += content + "\n\n"
        puts "  Added #{File.basename(file_path)}"
      else
        puts "  Warning: #{file_path} not found"
      end
    end

    target_file = File.join(builds_dir, "application.css")
    File.write(target_file, concatenated_css)
    puts "✓ Manual concatenation complete (#{File.size(target_file)} bytes)"
  end
end
