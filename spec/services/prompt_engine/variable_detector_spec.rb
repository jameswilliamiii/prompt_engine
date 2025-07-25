require 'rails_helper'

module PromptEngine
  RSpec.describe VariableDetector do
    describe '#extract_variables' do
      it 'extracts simple variables' do
        content = "Hello {{name}}, welcome to {{company}}!"
        detector = described_class.new(content)

        variables = detector.extract_variables

        expect(variables.length).to eq(2)
        expect(variables[0][:name]).to eq('name')
        expect(variables[1][:name]).to eq('company')
      end

      it 'handles variables with underscores and numbers' do
        content = "User {{user_id}} has {{item_count_2}} items"
        detector = described_class.new(content)

        variables = detector.extract_variables

        expect(variables.map { |v| v[:name] }).to eq([ 'user_id', 'item_count_2' ])
      end

      it 'removes duplicate variables' do
        content = "{{name}} is {{name}} and {{name}} again"
        detector = described_class.new(content)

        variables = detector.extract_variables

        expect(variables.length).to eq(1)
        expect(variables[0][:name]).to eq('name')
      end

      it 'returns empty array when no variables' do
        content = "Just plain text"
        detector = described_class.new(content)

        expect(detector.extract_variables).to be_empty
      end

      it 'includes position information' do
        content = "Hello {{name}}!"
        detector = described_class.new(content)

        variable = detector.extract_variables.first

        expect(variable[:position]).to eq([ 6, 14 ])
        expect(variable[:placeholder]).to eq('{{name}}')
      end

      it 'infers variable types' do
        content = "ID: {{user_id}}, Price: {{total_price}}, Active: {{is_active}}, Time: {{created_at}}"
        detector = described_class.new(content)

        variables = detector.extract_variables

        expect(variables.find { |v| v[:name] == 'user_id' }[:type]).to eq('integer')
        expect(variables.find { |v| v[:name] == 'total_price' }[:type]).to eq('decimal')
        expect(variables.find { |v| v[:name] == 'is_active' }[:type]).to eq('boolean')
        expect(variables.find { |v| v[:name] == 'created_at' }[:type]).to eq('datetime')
      end
    end

    describe '#variable_names' do
      it 'returns array of variable names' do
        content = "{{first}} and {{second}}"
        detector = described_class.new(content)

        expect(detector.variable_names).to eq([ 'first', 'second' ])
      end
    end

    describe '#has_variables?' do
      it 'returns true when variables present' do
        detector = described_class.new("Hello {{name}}")
        expect(detector.has_variables?).to be true
      end

      it 'returns false when no variables' do
        detector = described_class.new("Hello world")
        expect(detector.has_variables?).to be false
      end
    end

    describe '#variable_count' do
      it 'counts unique variables' do
        content = "{{a}} {{b}} {{a}} {{c}}"
        detector = described_class.new(content)

        expect(detector.variable_count).to eq(3)
      end
    end

    describe '#render' do
      it 'replaces variables with provided values' do
        content = "Hello {{name}}, welcome to {{place}}!"
        detector = described_class.new(content)

        result = detector.render(name: 'Alice', place: 'Wonderland')

        expect(result).to eq("Hello Alice, welcome to Wonderland!")
      end

      it 'handles string keys' do
        content = "Hello {{name}}"
        detector = described_class.new(content)

        result = detector.render('name' => 'Bob')

        expect(result).to eq("Hello Bob")
      end

      it 'leaves unmatched variables as is' do
        content = "{{greeting}} {{name}}!"
        detector = described_class.new(content)

        result = detector.render(greeting: 'Hi')

        expect(result).to eq("Hi {{name}}!")
      end

      it 'converts values to strings' do
        content = "Count: {{count}}, Price: {{price}}"
        detector = described_class.new(content)

        result = detector.render(count: 42, price: 19.99)

        expect(result).to eq("Count: 42, Price: 19.99")
      end
    end

    describe '#validate_variables' do
      let(:content) { "{{name}} owes {{amount}}" }
      let(:detector) { described_class.new(content) }

      it 'returns valid when all variables provided' do
        result = detector.validate_variables(name: 'Alice', amount: '100')

        expect(result[:valid]).to be true
        expect(result[:missing_variables]).to be_empty
      end

      it 'returns invalid with missing variables' do
        result = detector.validate_variables(name: 'Alice')

        expect(result[:valid]).to be false
        expect(result[:missing_variables]).to eq([ 'amount' ])
      end

      it 'handles string keys' do
        result = detector.validate_variables('name' => 'Alice', 'amount' => '100')

        expect(result[:valid]).to be true
      end

      it 'returns all missing variables' do
        result = detector.validate_variables({})

        expect(result[:valid]).to be false
        expect(result[:missing_variables]).to match_array([ 'name', 'amount' ])
      end
    end
  end
end
