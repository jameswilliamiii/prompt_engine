module PromptEngine
  class Error < StandardError; end
  class RenderError < Error; end
  class PromptNotFoundError < Error; end
end