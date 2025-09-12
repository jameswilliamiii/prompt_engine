# Pin the index file that exports registerControllers
pin "prompt_engine", to: "prompt_engine/index.js"

# Pin all the controller files so they can be imported
pin_all_from "app/javascript/prompt_engine/controllers", under: "prompt_engine/controllers"
