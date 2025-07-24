module ActivePrompt
  class Engine < ::Rails::Engine
    isolate_namespace ActivePrompt

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    # Ensure services directory is in the autoload paths
    # config.autoload_paths += %W[#{config.root}/app/services]

    # Ensure engine's migrations are available to the host app
    # This is the standard Rails engine pattern
    initializer :append_migrations do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
