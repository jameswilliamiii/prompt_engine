require "rails/generators/base"

module PromptEngine
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def add_route_mount
        return if routes_already_mounted?
        route "mount PromptEngine::Engine => '/prompt_engine'"
      end

      def create_initializer
        # copy_file "initializer.rb", "config/initializers/prompt_engine.rb"
      end

      def add_javascript_registration
        unless File.exist?("app/javascript/controllers/application.js")
          say "Stimulus not detected. Run: bin/rails stimulus:install", :yellow
          return
        end

        if importmap_available?
          configure_importmap
        else
          say_manual_configuration_needed
        end

        if File.exist?("app/javascript/application.js")
          append_to_application_js
        elsif File.exist?("app/javascript/controllers/index.js")
          append_to_controllers_index
        end
      end

      def add_stylesheet
        if using_sprockets?
          unless stylesheet_already_required?
            append_to_file "app/assets/stylesheets/application.css",
              "\n *= require prompt_engine/application\n"
          end
        else
          say <<~MESSAGE, :yellow
            Add to your layout where engine UI appears:
            <%= stylesheet_link_tag "prompt_engine/application", "data-turbo-track": "reload" %>
          MESSAGE
        end
      end

      def display_post_install
        say "\n✅ PromptEngine has been successfully installed!", :green
        say "\nNext steps:", :bold
        say "  1. Run: bin/rails prompt_engine:install:migrations"
        say "  2. Run: bin/rails db:migrate"
        say "  3. Configure AI provider API keys in Rails credentials"
        say "  4. Restart your Rails server"
        say "  5. Visit /prompt_engine to verify installation"
      end

      private

      def routes_already_mounted?
        File.read("config/routes.rb").include?("PromptEngine::Engine")
      end

      def stylesheet_already_required?
        File.read("app/assets/stylesheets/application.css").include?("prompt_engine/application")
      end

      def using_sprockets?
        File.exist?("app/assets/stylesheets/application.css") &&
          File.read("app/assets/stylesheets/application.css").include?("*= require")
      end

      def importmap_available?
        File.exist?("config/importmap.rb")
      end

      def configure_importmap
        return if importmap_already_configured?

        append_to_file "config/importmap.rb", <<~RUBY
          
          # PromptEngine
          pin "prompt_engine", to: "prompt_engine/index.js"
        RUBY

        say "✓ Added PromptEngine to Import Maps", :green
      end

      def importmap_already_configured?
        File.read("config/importmap.rb").include?("prompt_engine")
      end

      def append_to_application_js
        return if application_js_already_configured?

        append_to_file "app/javascript/application.js", <<~JS
          
          // PromptEngine Controllers
          import { application } from "controllers/application"
          import { registerControllers } from "prompt_engine"
          registerControllers(application)
        JS
      end

      def append_to_controllers_index
        return if controllers_index_already_configured?

        append_to_file "app/javascript/controllers/index.js", <<~JS
          
          // PromptEngine Controllers
          import { application } from "controllers/application"
          import { registerControllers } from "prompt_engine"
          registerControllers(application)
        JS
      end

      def application_js_already_configured?
        File.exist?("app/javascript/application.js") &&
          File.read("app/javascript/application.js").include?("registerControllers")
      end

      def controllers_index_already_configured?
        File.exist?("app/javascript/controllers/index.js") &&
          File.read("app/javascript/controllers/index.js").include?("registerControllers")
      end

      def say_manual_configuration_needed
        say <<~MESSAGE, :yellow
          ⚠️  Could not detect JavaScript configuration.
          
          Please manually integrate PromptEngine JavaScript:
          
          For Import Maps, add to config/importmap.rb:
            pin "prompt_engine", to: "prompt_engine/index.js"
          
          Then in app/javascript/application.js:
            import { application } from "controllers/application"
            import { registerControllers } from "prompt_engine"
            registerControllers(application)
        MESSAGE
      end
    end
  end
end
