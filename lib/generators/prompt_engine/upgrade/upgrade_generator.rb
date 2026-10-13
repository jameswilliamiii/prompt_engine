require "rails/generators"

module PromptEngine
  module Generators
    class UpgradeGenerator < Rails::Generators::Base
      desc "Copy any PromptEngine migrations the app doesn't have yet, then list the steps for this version."

      def install_migrations
        rake "prompt_engine:install:migrations"
      end

      def show_next_steps
        say <<~STEPS

          PromptEngine #{PromptEngine::VERSION} is installed. Next:

            1. bin/rails db:migrate
            2. Review UPGRADING.md for this version's configuration changes:
               https://github.com/jameswilliamiii/prompt_engine/blob/v#{PromptEngine::VERSION}/UPGRADING.md
        STEPS
      end
    end
  end
end
