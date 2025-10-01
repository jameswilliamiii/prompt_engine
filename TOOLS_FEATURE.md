# Tool Calls Feature

The PromptEngine now supports adding RubyLLM tools to prompts, allowing them to use tool calls during execution.

## Overview

This feature enables prompts to:
- Discover available RubyLLM::Tool classes in your application
- Select which tools to make available to a specific prompt
- Execute prompts with the selected tools attached

## How It Works

### 1. Tool Discovery

The system automatically discovers tools using three methods:
- Classes that include `RubyLLM::Tool`
- Classes that inherit from `RubyLLM::Tool`
- Classes with "tool" in their name that are valid tools

### 2. Tool Selection

Users can select tools through the prompt editing interface:
- Click "Add Tool" button in the prompt form
- Browse available tools in a modal
- Select tools to add to the prompt
- Remove tools as needed

### 3. Tool Execution

When a prompt is executed:
- Selected tools are loaded and validated
- Tools are attached to the RubyLLM chat instance
- The prompt can use tool calls during execution

## Usage

### Creating a Tool

Create a tool class that inherits from `RubyLLM::Tool`:

```ruby
class MyTool < RubyLLM::Tool
  description "Description of what this tool does"
  param :param1, desc: "Description of param1"
  param :param2, desc: "Description of param2"

  def execute(param1:, param2:)
    # Tool implementation
    { result: "some result" }
  rescue => e
    { error: e.message }
  end
end
```

### Adding Tools to a Prompt

1. Edit an existing prompt
2. Scroll to the "Tools" section
3. Click "Add Tool"
4. Select from available tools
5. Save the prompt

### Tool Information

The system extracts the following information from tools:
- Class name
- Description (from `description` or `tool_description` methods)
- Available methods
- Source location

## Database Changes

The feature adds two new JSON columns:
- `prompt_engine_prompts.tools` - stores selected tool class names
- `prompt_engine_prompt_versions.tools` - versioned tool selections

## API Endpoints

- `GET /prompts/:id/tools` - List selected tools
- `POST /prompts/:id/tools` - Add a tool
- `DELETE /prompts/:id/tools/:tool_class_name` - Remove a tool
- `GET /prompts/:id/tools/available` - List available tools

## Example

See `spec/dummy/app/tools/example_tool.rb` for a complete example tool implementation.

## Requirements

- RubyLLM gem must be installed
- Tool classes must be loaded by your Rails application
- Tools must inherit from `RubyLLM::Tool`
