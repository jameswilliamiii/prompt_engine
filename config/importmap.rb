# Pin the index file that exports registerControllers
pin "prompt_engine", to: "prompt_engine/index.js", preload: true

# Pin all the controller files so they can be imported
pin_all_from PromptEngine::Engine.root.join("app/javascript/prompt_engine/controllers"), under: "prompt_engine/controllers", to: "prompt_engine/controllers", preload: true
