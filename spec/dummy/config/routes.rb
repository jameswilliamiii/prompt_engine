Rails.application.routes.draw do
  # Basic mounting (authentication configured in initializer)
  mount PromptEngine::Engine => "/prompt_engine"

  # Example: Devise authentication
  # authenticate :user, ->(user) { user.admin? } do
  #   mount PromptEngine::Engine => "/prompt_engine"
  # end

  # Example: Custom authentication constraint
  # constraints ->(request) { request.session[:admin] == true } do
  #   mount PromptEngine::Engine => "/prompt_engine"
  # end

  root to: redirect("/prompt_engine")
end
