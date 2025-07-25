Rails.application.routes.draw do
  mount PromptEngine::Engine => "/prompt_engine"

  root to: redirect("/prompt_engine")
end
