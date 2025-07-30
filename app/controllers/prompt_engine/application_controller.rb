module PromptEngine
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    
    # Allow host applications to add authentication
    # and other controller-level customizations via:
    #
    # ActiveSupport.on_load(:prompt_engine_application_controller) do
    #   # Add your authentication logic here
    # end
    #
    # See AUTH.md for detailed authentication examples
    ActiveSupport.run_load_hooks(:prompt_engine_application_controller, self)
  end
end
