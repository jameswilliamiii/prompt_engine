Rails.application.routes.draw do
  mount ActivePrompt::Engine => "/active_prompt"
  
  root to: redirect("/active_prompt")
end
