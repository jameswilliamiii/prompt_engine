require 'ruby_llm'

module PromptEngine
  class ToolDiscoveryService
    class << self
      # Discover all available RubyLLM::Tool classes in the application
      def discover_tools
        tools = []
        
        # Method 1: Scan tools directory for Ruby files
        tools.concat(find_tools_in_directory)
        
        # Method 2: Search for classes that include RubyLLM::Tool
        tools.concat(find_tool_classes_by_inclusion)
        
        # Method 3: Search for classes that inherit from RubyLLM::Tool
        tools.concat(find_tool_classes_by_inheritance)
        
        # Method 4: Search for classes with "tool" in their name or namespace
        tools.concat(find_tool_classes_by_name)
        
        # Remove duplicates and return tool info
        tools.uniq { |tool| tool.name }.map do |tool_class|
          tool_info(tool_class)
        end
      end

      # Get tool information for display in UI
      def tool_info(tool_class)
        return nil unless tool_class.respond_to?(:name)
        
        {
          name: tool_class.name,
          description: extract_description(tool_class),
          methods: extract_tool_methods(tool_class),
          source_location: extract_source_location(tool_class)
        }
      end

      # Validate that a class is a valid tool
      def valid_tool?(tool_class)
        return false unless tool_class.is_a?(Class)
        return false unless ruby_llm_available?
        
        # Check if it includes RubyLLM::Tool or inherits from it
        includes_tool = tool_class.included_modules.include?(RubyLLM::Tool)
        inherits_tool = tool_class < RubyLLM::Tool rescue false
        
        includes_tool || inherits_tool
      end

      private

      def find_tool_classes_by_inclusion
        return [] unless ruby_llm_available?
        
        ObjectSpace.each_object(Class).select do |klass|
          klass.included_modules.include?(RubyLLM::Tool)
        end
      end

      def find_tool_classes_by_inheritance
        return [] unless ruby_llm_available?
        
        ObjectSpace.each_object(Class).select do |klass|
          next false unless klass.name # Skip classes without names
          klass < RubyLLM::Tool rescue false
        end
      end

      def find_tool_classes_by_name
        # Search for classes with "tool" in their name or namespace
        ObjectSpace.each_object(Class).select do |klass|
          next false unless klass.name # Skip classes without names
          name = klass.name.to_s.downcase
          name.include?('tool') && valid_tool?(klass)
        end
      end

      def find_tools_in_directory
        tools = []
        
        # Look for tools in common directories
        tool_directories = [
          Rails.root.join('app', 'tools'),
          Rails.root.join('lib', 'tools'),
          Rails.root.join('tools'),
          Rails.root.join('app', 'lib', 'tools')
        ]
        
        tool_directories.each do |dir|
          next unless Dir.exist?(dir)
          
          # Find all Ruby files in the directory
          ruby_files = Dir.glob(File.join(dir, '**', '*.rb'))
          
          ruby_files.each do |file_path|
            tool_class = infer_tool_class_from_file(file_path)
            if tool_class && valid_tool?(tool_class)
              tools << tool_class
            end
          end
        end
        
        tools
      end

      def infer_tool_class_from_file(file_path)
        # Read the file to find the class name
        content = File.read(file_path)
        
        # Look for class definitions that inherit from RubyLLM::Tool
        class_match = content.match(/class\s+(\w+)\s*<\s*RubyLLM::Tool/)
        return nil unless class_match
        
        class_name = class_match[1]
        
        # Try to load the class
        begin
          require file_path
          class_name.constantize
        rescue => e
          Rails.logger.warn("Could not load tool class #{class_name} from #{file_path}: #{e.message}") if defined?(Rails)
          nil
        end
      end

      def ruby_llm_available?
        !!(defined?(RubyLLM) && defined?(RubyLLM::Tool))
      end

      def extract_description(tool_class)
        # Try to get description from RubyLLM::Tool class method
        if tool_class.respond_to?(:description) && tool_class.description.present?
          tool_class.description
        elsif tool_class.respond_to?(:tool_description) && tool_class.tool_description.present?
          tool_class.tool_description
        else
          # Try to extract from class comment or first line of source
          source = extract_source_location(tool_class)
          if source && File.exist?(source[:file])
            extract_comment_description(source[:file], source[:line])
          else
            "Tool: #{tool_class.name}"
          end
        end
      end

      def extract_tool_methods(tool_class)
        return [] unless tool_class.respond_to?(:instance_methods)
        
        # Get public methods that might be tool methods
        methods = tool_class.instance_methods(false)
        
        # Filter out common Ruby methods and focus on tool-specific ones
        tool_methods = methods.reject do |method|
          %w[initialize to_s inspect class superclass].include?(method.to_s)
        end
        
        # For RubyLLM::Tool, the main method is usually 'execute'
        begin
          if tool_class < RubyLLM::Tool
            ['execute'] + tool_methods.reject { |m| m.to_s == 'execute' }
          else
            tool_methods
          end
        rescue
          tool_methods
        end
      end

      def extract_source_location(tool_class)
        return nil unless tool_class.respond_to?(:source_location)
        
        file, line = tool_class.source_location
        return nil unless file && line
        
        {
          file: file,
          line: line
        }
      end

      def extract_comment_description(file_path, start_line)
        return nil unless File.exist?(file_path)
        
        lines = File.readlines(file_path)
        return nil if start_line > lines.length
        
        # Look for comment above the class definition
        comment_lines = []
        (start_line - 1).downto(1) do |line_num|
          line = lines[line_num - 1].strip
          break if line.empty? || !line.start_with?('#')
          comment_lines.unshift(line.sub(/^#\s*/, ''))
        end
        
        comment_lines.join(' ').strip.presence
      end
    end
  end
end
