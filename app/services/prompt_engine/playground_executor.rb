module PromptEngine
  class PlaygroundExecutor
    attr_reader :prompt, :provider, :api_key, :parameters

    MODELS = {
      "anthropic" => "claude-3-7",
      "openai" => "gpt-4o"
    }.freeze

    # Supported file types and their corresponding RubyLLM methods
    FILE_TYPE_METHODS = {
      pdf: :attach_file,
      image: :attach_file,
      jpg: :attach_file,
      jpeg: :attach_file,
      png: :attach_file,
      gif: :attach_file,
      webp: :attach_file
    }.freeze

    def initialize(prompt:, provider:, api_key:, parameters: {})
      @prompt = prompt
      @provider = provider
      @api_key = api_key
      @parameters = parameters || {}
    end

    def execute
      validate_inputs!

      start_time = Time.current

      # Extract files from parameters if present
      files = extract_files_from_parameters

      # Replace parameters in prompt content (excluding files)
      parser = ParameterParser.new(prompt.content)
      processed_content = parser.replace_parameters(parameters.except(:files, "files"))
      
      # Ensure JSON instruction is present when json_mode is enabled
      if prompt.respond_to?(:json_mode) && prompt.json_mode
        # Check if the content already mentions JSON
        unless processed_content.downcase.include?('json')
          processed_content = "#{processed_content}\n\nPlease respond with valid JSON format."
        end
      end

      # Configure RubyLLM with the appropriate API key
      configure_ruby_llm

      # Create chat instance with the model
      chat = RubyLLM.chat(model: MODELS[provider])

      # Enable structured JSON output if json_mode is on for the prompt
      if prompt.respond_to?(:json_mode) && prompt.json_mode
        begin
          if chat.respond_to?(:with_params)
            chat = chat.with_params(response_format: { type: "json_object" })
          elsif chat.respond_to?(:with_response_format)
            chat = chat.with_response_format(type: "json_object")
          end
        rescue => e
          Rails.logger.debug("PlaygroundExecutor json_mode setup failed: #{e.class} #{e.message}") if defined?(Rails)
        end
      end

      # Apply temperature if specified
      if prompt.temperature.present?
        chat = chat.with_temperature(prompt.temperature)
      end

      # Apply system message if present
      if prompt.system_message.present?
        chat = chat.with_instructions(prompt.system_message)
      end

      # Apply tools if present
      if prompt.respond_to?(:tools) && prompt.tools.present?
        selected_tools = load_selected_tools(prompt.tools)
        selected_tools.each do |tool_class|
          chat = chat.with_tool(tool_class)
        end
      end

      # Attach files if provided - try different approaches based on RubyLLM version
      files.each do |file_info|
        file_path = file_info[:file]

        # Try different methods to attach files
        if chat.respond_to?(:with_file)
          chat = chat.with_file(file_path)
        elsif chat.respond_to?(:attach_file)
          chat = chat.attach_file(file_path)
        elsif chat.respond_to?(:with_pdf) && file_info[:type] == :pdf
          chat = chat.with_pdf(file_path)
        elsif chat.respond_to?(:with_image) && file_info[:type] == :image
          chat = chat.with_image(file_path)
        else
          # Fallback: include file path in the prompt content
          processed_content = "#{processed_content}\n\n[File attached: #{file_path}]"
        end
      end

      # Execute the prompt
      # Note: max_tokens may need to be passed differently depending on RubyLLM version
      response = chat.ask(processed_content)

      execution_time = (Time.current - start_time).round(3)

      # Handle response based on its structure
      response_content = if response.respond_to?(:content)
        response.content
      elsif response.is_a?(String)
        response
      else
        response.to_s
      end

      # Try to get token count if available
      token_count = if response.respond_to?(:input_tokens) && response.respond_to?(:output_tokens)
        (response.input_tokens || 0) + (response.output_tokens || 0)
      else
        0 # Default if token information isn't available
      end

      {
        response: response_content,
        execution_time: execution_time,
        token_count: token_count,
        model: MODELS[provider],
        provider: provider
      }
    rescue => e
      handle_error(e)
    end

    private

    def extract_files_from_parameters
      files = parameters[:files] || parameters["files"] || []
      files = [ files ] unless files.is_a?(Array)

      # Filter out empty/blank files and process valid ones
      files.compact.reject(&:blank?).map do |file|
        # Skip if file is an empty string or effectively empty
        next if file.is_a?(String) && file.strip.empty?
        next if file.respond_to?(:original_filename) && file.original_filename.blank?
        next if file.respond_to?(:size) && file.size == 0

        file_type = determine_file_type(file)
        method_name = FILE_TYPE_METHODS[file_type]

        raise ArgumentError, "Unsupported file type: #{file_type}. File: #{file.inspect}" unless method_name

        {
          file: file,
          type: file_type,
          method: method_name
        }
      end.compact
    end

    def determine_file_type(file)
      filename = if file.is_a?(String)
                   file
      elsif file.respond_to?(:original_filename) && file.original_filename.present?
                   file.original_filename
      elsif file.respond_to?(:path) && file.path.present?
                   file.path
      elsif file.respond_to?(:tempfile) && file.tempfile.respond_to?(:path)
                   file.tempfile.path
      else
                   raise ArgumentError, "Cannot determine filename for: #{file.inspect}"
      end

      return :unknown if filename.blank?

      extension = File.extname(filename).downcase.sub(".", "")

      return :unknown if extension.blank?

      # Map extensions to file types
      case extension
      when "pdf"
        :pdf
      when "jpg", "jpeg", "png", "gif", "webp"
        :image
      else
        # For unknown extensions, try to map them if they're in our supported list
        ext_symbol = extension.to_sym
        FILE_TYPE_METHODS.key?(ext_symbol) ? ext_symbol : :unknown
      end
    end

    def validate_inputs!
      raise ArgumentError, "Provider is required" if provider.blank?
      raise ArgumentError, "API key is required" if api_key.blank?
      raise ArgumentError, "Invalid provider" unless MODELS.key?(provider)

      # Validate API key format
      validate_api_key_format!

      # Validate files if present in parameters
      files = extract_files_from_parameters
      if files.any?
        files.each do |file_info|
          validate_file(file_info[:file])
        end
      end
    end

    def validate_api_key_format!
      case provider
      when "anthropic"
        unless api_key.start_with?("sk-ant-")
          raise ArgumentError, "Invalid Anthropic API key format. Expected format: sk-ant-..."
        end
      when "openai"
        unless api_key.start_with?("sk-")
          raise ArgumentError, "Invalid OpenAI API key format. Expected format: sk-..."
        end
      end
    end

    def validate_file(file)
      # Handle both file paths and file objects
      if file.is_a?(String)
        # File path validation
        raise ArgumentError, "File does not exist: #{file}" unless File.exist?(file)
        raise ArgumentError, "File is not readable: #{file}" unless File.readable?(file)
      elsif file.respond_to?(:original_filename) || file.respond_to?(:path) || file.respond_to?(:tempfile)
        # File upload object validation - basic check that it responds to expected methods
        filename = if file.respond_to?(:original_filename) && file.original_filename.present?
                     file.original_filename
        elsif file.respond_to?(:path) && file.path.present?
                     file.path
        elsif file.respond_to?(:tempfile) && file.tempfile.respond_to?(:path)
                     file.tempfile.path
        end

        raise ArgumentError, "Invalid file object - cannot determine filename: #{file.inspect}" if filename.blank?
      else
        raise ArgumentError, "Invalid file format. Expected file path or file object, got: #{file.class}"
      end

      # Validate file type is supported
      file_type = determine_file_type(file)
      if file_type == :unknown || !FILE_TYPE_METHODS.key?(file_type)
        raise ArgumentError, "Unsupported file type: #{file_type}. Supported types: #{FILE_TYPE_METHODS.keys.join(', ')}. File: #{file.inspect}"
      end
    end

    def configure_ruby_llm
      require "ruby_llm"

      # Clear any existing configuration first
      RubyLLM.reset! if RubyLLM.respond_to?(:reset!)

      case provider
      when "anthropic"
        RubyLLM.configure do |config|
          config.anthropic_api_key = api_key.strip
        end
      when "openai"
        RubyLLM.configure do |config|
          config.openai_api_key = api_key.strip
        end
      end
    end

    def load_selected_tools(tool_class_names)
      return [] unless tool_class_names.is_a?(Array)
      
      tool_class_names.map do |tool_name|
        # Try to constantize the tool class name
        begin
          tool_class = tool_name.constantize
          # Validate that it's a proper tool
          if PromptEngine::ToolDiscoveryService.valid_tool?(tool_class)
            tool_class
          else
            Rails.logger.warn("Invalid tool class: #{tool_name}") if defined?(Rails)
            nil
          end
        rescue NameError => e
          Rails.logger.warn("Tool class not found: #{tool_name} - #{e.message}") if defined?(Rails)
          nil
        end
      end.compact
    end

    def handle_error(error)
      # Re-raise ArgumentError as-is for validation errors
      raise error if error.is_a?(ArgumentError)

      # Check for specific error types and messages
      error_message = error.message.to_s.downcase

      case error
      when Net::HTTPUnauthorized
        raise "Invalid API key"
      when Net::HTTPTooManyRequests
        raise "Rate limit exceeded. Please try again later."
      when Net::HTTPError
        raise "Network error. Please check your connection and try again."
      else
        # Check error message patterns
        case error_message
        when /invalid.*api.?key/i, /unauthorized/i, /invalid x-api-key/i
          raise "Invalid API key. Please check your #{provider.capitalize} API key."
        when /rate limit/i
          raise "Rate limit exceeded. Please try again later."
        when /network/i, /connection/i
          raise "Network error. Please check your connection and try again."
        when /model.*not found/i
          raise "Model not available. Please try a different model."
        else
          raise "An error occurred: #{error.message}"
        end
      end
    end
  end
end
