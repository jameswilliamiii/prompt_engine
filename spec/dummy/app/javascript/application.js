// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// PromptEngine Controllers
import { application } from "controllers/application"
import { registerControllers } from "prompt_engine"
registerControllers(application)
