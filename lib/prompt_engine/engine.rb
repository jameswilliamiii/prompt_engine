module PromptEngine
  class Engine < ::Rails::Engine
    isolate_namespace PromptEngine

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    # Ensure services and clients directories are in the autoload paths
    config.autoload_paths += %W[#{config.root}/app/services]
    config.autoload_paths += %W[#{config.root}/app/clients]

    # IMPORTANT: Migrations are NOT automatically loaded!
    # Users must explicitly install migrations using:
    #   bin/rails prompt_engine:install:migrations
    #
    # This ensures host applications have full control over when
    # engine migrations are added to their codebase.
    #
    # The following initializer is intentionally disabled:
    # initializer :append_migrations do |app|
    #   unless app.root.to_s.match?(root.to_s) || app.root.to_s.include?('spec/dummy')
    #     config.paths["db/migrate"].expanded.each do |expanded_path|
    #       app.config.paths["db/migrate"] << expanded_path
    #     end
    #   end
    # end

    # Define the controller hook for authentication customization
    initializer "prompt_engine.controller_hook" do
      ActiveSupport.on_load(:prompt_engine_application_controller) do
        # This hook allows host applications to add authentication
        # and other controller-level customizations
      end
    end

    # Allow middleware to be added for authentication
    # Example: PromptEngine::Engine.middleware.use(Rack::Auth::Basic) { ... }
  end
end
