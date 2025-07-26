module PromptEngine
  class ApplicationController < ActionController::Base
    include PromptEngine::Authentication

    # Run the ActiveSupport hook to allow host app customization
    ActiveSupport.run_load_hooks(:prompt_engine_application_controller, self)
  end
end
