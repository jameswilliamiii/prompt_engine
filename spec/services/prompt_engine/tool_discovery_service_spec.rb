require 'rails_helper'

RSpec.describe PromptEngine::ToolDiscoveryService do
  describe '.discover_tools' do
    it 'returns an array of tool classes' do
      tools = described_class.discover_tools
      expect(tools).to be_an(Array)
    end
  end

  describe '.tool_info' do
    let(:tool_class) { double('ToolClass', name: 'TestTool') }

    before do
      allow(described_class).to receive(:extract_description).and_return('Test description')
      allow(described_class).to receive(:extract_tool_methods).and_return(['method1', 'method2'])
      allow(described_class).to receive(:extract_source_location).and_return({ file: 'test.rb', line: 1 })
    end

    it 'returns tool information hash' do
      info = described_class.tool_info(tool_class)
      
      expect(info).to include(
        name: 'TestTool',
        description: 'Test description',
        methods: ['method1', 'method2'],
        source_location: { file: 'test.rb', line: 1 }
      )
    end
  end

  describe '.valid_tool?' do
    let(:valid_tool_class) { double('ValidTool', is_a?: true) }
    let(:invalid_class) { double('InvalidClass', is_a?: true) }

    context 'when RubyLLM is available' do
      let(:tool_module) { Module.new }
      let(:ruby_llm_module) { Module.new }

      before do
        stub_const('RubyLLM', ruby_llm_module)
        stub_const('RubyLLM::Tool', tool_module)
        # Mock both inclusion and inheritance for valid tool
        allow(valid_tool_class).to receive(:included_modules).and_return([tool_module])
        allow(valid_tool_class).to receive(:<).with(tool_module).and_return(true)
        # Mock both inclusion and inheritance for invalid class
        allow(invalid_class).to receive(:included_modules).and_return([])
        allow(invalid_class).to receive(:<).with(tool_module).and_return(false)
      end

      it 'returns true for valid tool classes' do
        result = described_class.valid_tool?(valid_tool_class)
        expect(result).to be true
      end

      it 'returns false for invalid classes' do
        expect(described_class.valid_tool?(invalid_class)).to be false
      end
    end

    context 'when RubyLLM is not available' do
      before do
        hide_const('RubyLLM') if defined?(RubyLLM)
      end

      it 'returns false for any class' do
        expect(described_class.valid_tool?(valid_tool_class)).to be false
        expect(described_class.valid_tool?(invalid_class)).to be false
      end
    end
  end
end
