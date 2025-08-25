// PromptEngine Stimulus Controllers
import PlaygroundController from "./controllers/playground_controller"
import PromptFormController from "./controllers/prompt_form_controller"
import VariableDetectorController from "./controllers/variable_detector_controller"

// Export registration function for host app
export function registerControllers(application) {
  application.register("prompt-engine--playground", PlaygroundController)
  application.register("prompt-engine--prompt-form", PromptFormController)
  application.register("prompt-engine--variable-detector", VariableDetectorController)
  
  console.log("PromptEngine controllers registered:", {
    playground: PlaygroundController,
    promptForm: PromptFormController,
    variableDetector: VariableDetectorController
  })
}