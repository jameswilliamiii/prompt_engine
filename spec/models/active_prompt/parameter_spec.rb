require 'rails_helper'

RSpec.describe ActivePrompt::Parameter, type: :model do
  describe 'validations' do
    let(:prompt) { create(:prompt) }
    let(:parameter) { build(:parameter, prompt: prompt) }

    context 'name validation' do
      it 'validates presence of name' do
        parameter = build(:parameter, name: nil, prompt: prompt)
        expect(parameter).not_to be_valid
        expect(parameter.errors[:name]).to include("can't be blank")
      end

      it 'validates uniqueness of name scoped to prompt' do
        existing_param = create(:parameter, name: 'user_name', prompt: prompt)
        
        duplicate = build(:parameter, name: 'user_name', prompt: prompt)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include("has already been taken")
        
        # Same name for different prompt should be valid
        other_prompt = create(:prompt)
        different_prompt_param = build(:parameter, name: 'user_name', prompt: other_prompt)
        expect(different_prompt_param).to be_valid
      end

      it 'validates format of name' do
        # Valid names
        %w[name user_name _private user123 USER_NAME].each do |valid_name|
          parameter.name = valid_name
          parameter.valid?
          expect(parameter.errors[:name]).to be_empty
        end

        # Invalid names
        ['123name', 'user-name', 'user name', 'user.name', ''].each do |invalid_name|
          parameter.name = invalid_name
          expect(parameter).not_to be_valid
          expect(parameter.errors[:name]).to include("must start with a letter or underscore and contain only letters, numbers, and underscores")
        end
      end
    end

    context 'parameter_type validation' do
      it 'does not allow invalid parameter types' do
        parameter = build(:parameter, prompt: prompt)
        parameter.parameter_type = 'invalid_type'
        expect(parameter).not_to be_valid
        expect(parameter.errors[:parameter_type]).to include("is not included in the list")
      end

      it 'validates inclusion in TYPES' do
        ActivePrompt::Parameter::TYPES.each do |valid_type|
          parameter.parameter_type = valid_type
          parameter.valid?
          expect(parameter.errors[:parameter_type]).to be_empty
        end
      end
    end

    context 'required validation' do
      it 'validates inclusion of required' do
        parameter.required = true
        expect(parameter).to be_valid

        parameter.required = false
        expect(parameter).to be_valid
      end
    end
  end

  describe 'associations' do
    it 'belongs to prompt' do
      association = ActivePrompt::Parameter.reflect_on_association(:prompt)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:class_name]).to eq('ActivePrompt::Prompt')
    end
  end

  describe 'scopes' do
    let(:prompt) { create(:prompt) }
    let!(:required_param1) { create(:parameter, prompt: prompt, required: true, position: 2) }
    let!(:required_param2) { create(:parameter, prompt: prompt, required: true, position: 1) }
    let!(:optional_param1) { create(:parameter, prompt: prompt, required: false, position: 3) }
    let!(:optional_param2) { create(:parameter, prompt: prompt, required: false, position: nil) }

    describe '.required' do
      it 'returns only required parameters' do
        expect(ActivePrompt::Parameter.required).to contain_exactly(required_param1, required_param2)
      end
    end

    describe '.optional' do
      it 'returns only optional parameters' do
        expect(ActivePrompt::Parameter.optional).to contain_exactly(optional_param1, optional_param2)
      end
    end

    describe '.ordered' do
      it 'returns parameters ordered by position (nulls first) then created_at' do
        # In most SQL databases, NULL values come first when ordering ASC
        # Parameters are ordered by: position ASC (nulls first), then created_at ASC
        ordered = prompt.parameters.ordered.to_a
        
        # First should be the parameter with NULL position (oldest created_at)
        expect(ordered.first).to eq(optional_param2)
        
        # Then parameters with positions in ascending order
        expect(ordered[1]).to eq(required_param2) # position 1
        expect(ordered[2]).to eq(required_param1) # position 2
        expect(ordered[3]).to eq(optional_param1) # position 3
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      it 'sets default parameter_type to string' do
        parameter = ActivePrompt::Parameter.new(name: 'test', prompt: create(:prompt))
        parameter.valid?
        expect(parameter.parameter_type).to eq('string')
      end

      it 'sets default required to true' do
        parameter = ActivePrompt::Parameter.new(name: 'test', prompt: create(:prompt))
        parameter.valid?
        expect(parameter.required).to be true
      end

      it 'does not override existing values' do
        parameter = ActivePrompt::Parameter.new(
          name: 'test',
          prompt: create(:prompt),
          parameter_type: 'integer',
          required: false
        )
        parameter.valid?
        expect(parameter.parameter_type).to eq('integer')
        expect(parameter.required).to be false
      end
    end
  end

  describe '#cast_value' do
    let(:prompt) { create(:prompt) }

    context 'when parameter is optional and value is blank' do
      let(:parameter) { create(:parameter, prompt: prompt, required: false, default_value: 'default') }
      
      it 'returns default_value' do
        expect(parameter.cast_value('')).to eq('default')
        expect(parameter.cast_value(nil)).to eq('default')
      end
    end

    context 'string type' do
      let(:parameter) { create(:parameter, prompt: prompt, parameter_type: 'string') }

      it 'converts value to string' do
        expect(parameter.cast_value('hello')).to eq('hello')
        expect(parameter.cast_value(123)).to eq('123')
        expect(parameter.cast_value(true)).to eq('true')
      end
    end

    context 'integer type' do
      let(:parameter) { create(:parameter, prompt: prompt, parameter_type: 'integer') }

      it 'converts value to integer' do
        expect(parameter.cast_value('123')).to eq(123)
        expect(parameter.cast_value(456.78)).to eq(456)
        expect(parameter.cast_value('abc')).to eq(0)
      end
    end

    context 'decimal type' do
      let(:parameter) { create(:parameter, prompt: prompt, parameter_type: 'decimal') }

      it 'converts value to float' do
        expect(parameter.cast_value('123.45')).to eq(123.45)
        expect(parameter.cast_value(456)).to eq(456.0)
        expect(parameter.cast_value('abc')).to eq(0.0)
      end
    end

    context 'boolean type' do
      let(:parameter) { create(:parameter, prompt: prompt, parameter_type: 'boolean') }

      it 'converts value to boolean' do
        expect(parameter.cast_value('true')).to be true
        expect(parameter.cast_value('1')).to be true
        expect(parameter.cast_value('yes')).to be true
        expect(parameter.cast_value('false')).to be false
        expect(parameter.cast_value('0')).to be false
        # ActiveModel::Type::Boolean doesn't recognize 'no' as false by default
        expect(parameter.cast_value('no')).to be true
        # Empty string on a required boolean returns nil
        expect(parameter.cast_value('')).to be_nil
      end
    end

    context 'datetime type' do
      let(:parameter) { create(:parameter, prompt: prompt, parameter_type: 'datetime') }

      it 'converts valid datetime strings' do
        result = parameter.cast_value('2024-01-15 10:30:00')
        expect(result).to be_a(DateTime)
        expect(result.strftime('%Y-%m-%d %H:%M:%S')).to eq('2024-01-15 10:30:00')
      end

      it 'returns nil for invalid datetime' do
        expect(parameter.cast_value('invalid')).to be_nil
      end
    end

    context 'date type' do
      let(:parameter) { create(:parameter, prompt: prompt, parameter_type: 'date') }

      it 'converts valid date strings' do
        result = parameter.cast_value('2024-01-15')
        expect(result).to be_a(Date)
        expect(result.to_s).to eq('2024-01-15')
      end

      it 'returns nil for invalid date' do
        expect(parameter.cast_value('invalid')).to be_nil
      end
    end

    context 'array type' do
      let(:parameter) { create(:parameter, prompt: prompt, parameter_type: 'array') }

      it 'returns array if already an array' do
        expect(parameter.cast_value(['a', 'b', 'c'])).to eq(['a', 'b', 'c'])
      end

      it 'splits comma-separated string into array' do
        expect(parameter.cast_value('a,b,c')).to eq(['a', 'b', 'c'])
        expect(parameter.cast_value('a, b, c')).to eq(['a', 'b', 'c'])
      end
    end

    context 'json type' do
      let(:parameter) { create(:parameter, prompt: prompt, parameter_type: 'json') }

      it 'returns value if already a hash' do
        hash = { 'key' => 'value' }
        expect(parameter.cast_value(hash)).to eq(hash)
      end

      it 'parses valid JSON string' do
        expect(parameter.cast_value('{"key":"value"}')).to eq({ 'key' => 'value' })
      end

      it 'returns empty hash for invalid JSON' do
        expect(parameter.cast_value('invalid json')).to eq({})
      end
    end
  end

  describe '#validate_value' do
    let(:prompt) { create(:prompt) }

    context 'required validation' do
      let(:parameter) { create(:parameter, prompt: prompt, name: 'username', required: true) }

      it 'returns error when value is blank and parameter is required' do
        errors = parameter.validate_value('')
        expect(errors).to include('username is required')
        
        errors = parameter.validate_value(nil)
        expect(errors).to include('username is required')
      end

      it 'returns no error when value is present' do
        errors = parameter.validate_value('john')
        expect(errors).to be_empty
      end
    end

    context 'min_length validation' do
      let(:parameter) do
        create(:parameter, 
          prompt: prompt,
          name: 'username',
          validation_rules: { 'min_length' => 3 }
        )
      end

      it 'returns error when value is too short' do
        errors = parameter.validate_value('ab')
        expect(errors).to include('username must be at least 3 characters')
      end

      it 'returns no error when value meets min_length' do
        errors = parameter.validate_value('abc')
        expect(errors).to be_empty
      end
    end

    context 'max_length validation' do
      let(:parameter) do
        create(:parameter,
          prompt: prompt,
          name: 'username',
          validation_rules: { 'max_length' => 10 }
        )
      end

      it 'returns error when value is too long' do
        errors = parameter.validate_value('12345678901')
        expect(errors).to include('username must be at most 10 characters')
      end

      it 'returns no error when value is within max_length' do
        errors = parameter.validate_value('1234567890')
        expect(errors).to be_empty
      end
    end

    context 'pattern validation' do
      let(:parameter) do
        create(:parameter,
          prompt: prompt,
          name: 'email',
          validation_rules: { 'pattern' => '^[\w\.-]+@[\w\.-]+\.\w+$' }
        )
      end

      it 'returns error when value does not match pattern' do
        errors = parameter.validate_value('invalid-email')
        expect(errors).to include('email must match pattern: ^[\w\.-]+@[\w\.-]+\.\w+$')
      end

      it 'returns no error when value matches pattern' do
        errors = parameter.validate_value('user@example.com')
        expect(errors).to be_empty
      end
    end

    context 'min validation for numeric types' do
      let(:parameter) do
        create(:parameter,
          prompt: prompt,
          name: 'age',
          parameter_type: 'integer',
          validation_rules: { 'min' => 18 }
        )
      end

      it 'returns error when value is less than min' do
        errors = parameter.validate_value('17')
        expect(errors).to include('age must be at least 18')
      end

      it 'returns no error when value meets min' do
        errors = parameter.validate_value('18')
        expect(errors).to be_empty
      end
    end

    context 'max validation for numeric types' do
      let(:parameter) do
        create(:parameter,
          prompt: prompt,
          name: 'age',
          parameter_type: 'integer',
          validation_rules: { 'max' => 100 }
        )
      end

      it 'returns error when value exceeds max' do
        errors = parameter.validate_value('101')
        expect(errors).to include('age must be at most 100')
      end

      it 'returns no error when value is within max' do
        errors = parameter.validate_value('100')
        expect(errors).to be_empty
      end
    end

    context 'multiple validation rules' do
      let(:parameter) do
        create(:parameter,
          prompt: prompt,
          name: 'username',
          required: true,
          validation_rules: {
            'min_length' => 3,
            'max_length' => 20,
            'pattern' => '^[a-zA-Z0-9_]+$'
          }
        )
      end

      it 'returns all applicable errors' do
        errors = parameter.validate_value('')
        expect(errors).to include('username is required')

        errors = parameter.validate_value('ab')
        expect(errors).to include('username must be at least 3 characters')

        errors = parameter.validate_value('user-name-with-dashes')
        expect(errors).to include('username must match pattern: ^[a-zA-Z0-9_]+$')
        expect(errors).to include('username must be at most 20 characters')
      end

      it 'returns no errors when all rules pass' do
        errors = parameter.validate_value('valid_user123')
        expect(errors).to be_empty
      end
    end
  end

  describe '#form_input_options' do
    let(:prompt) { create(:prompt) }

    context 'common options' do
      let(:parameter) do
        create(:parameter,
          prompt: prompt,
          name: 'user_name',
          description: 'Enter your username',
          example_value: 'john_doe',
          required: true,
          default_value: 'guest'
        )
      end

      it 'includes basic options' do
        options = parameter.form_input_options
        expect(options[:label]).to eq('User name')
        expect(options[:required]).to be true
        expect(options[:placeholder]).to eq('john_doe')
        expect(options[:hint]).to eq('Enter your username')
        expect(options[:value]).to eq('guest')
      end
    end

    context 'string type' do
      let(:parameter) do
        create(:parameter,
          prompt: prompt,
          parameter_type: 'string',
          validation_rules: {
            'min_length' => 3,
            'max_length' => 20,
            'pattern' => '^[a-zA-Z]+$'
          }
        )
      end

      it 'returns text input options with constraints' do
        options = parameter.form_input_options
        expect(options[:type]).to eq('text')
        expect(options[:minlength]).to eq(3)
        expect(options[:maxlength]).to eq(20)
        expect(options[:pattern]).to eq('^[a-zA-Z]+$')
      end
    end

    context 'integer type' do
      let(:parameter) do
        create(:parameter,
          prompt: prompt,
          parameter_type: 'integer',
          validation_rules: { 'min' => 0, 'max' => 100 }
        )
      end

      it 'returns number input options' do
        options = parameter.form_input_options
        expect(options[:type]).to eq('number')
        expect(options[:step]).to eq('1')
        expect(options[:min]).to eq(0)
        expect(options[:max]).to eq(100)
      end
    end

    context 'decimal type' do
      let(:parameter) do
        create(:parameter,
          prompt: prompt,
          parameter_type: 'decimal',
          validation_rules: { 'min' => 0.0, 'max' => 99.99 }
        )
      end

      it 'returns number input options with decimal step' do
        options = parameter.form_input_options
        expect(options[:type]).to eq('number')
        expect(options[:step]).to eq('0.01')
        expect(options[:min]).to eq(0.0)
        expect(options[:max]).to eq(99.99)
      end
    end

    context 'boolean type' do
      let(:parameter) { create(:parameter, prompt: prompt, parameter_type: 'boolean') }

      it 'returns checkbox input options' do
        options = parameter.form_input_options
        expect(options[:type]).to eq('checkbox')
      end
    end

    context 'datetime type' do
      let(:parameter) { create(:parameter, prompt: prompt, parameter_type: 'datetime') }

      it 'returns datetime-local input options' do
        options = parameter.form_input_options
        expect(options[:type]).to eq('datetime-local')
      end
    end

    context 'date type' do
      let(:parameter) { create(:parameter, prompt: prompt, parameter_type: 'date') }

      it 'returns date input options' do
        options = parameter.form_input_options
        expect(options[:type]).to eq('date')
      end
    end

    context 'array type' do
      let(:parameter) do
        create(:parameter,
          prompt: prompt,
          parameter_type: 'array',
          description: 'List of tags'
        )
      end

      it 'returns text input with array hint' do
        options = parameter.form_input_options
        expect(options[:type]).to eq('text')
        expect(options[:hint]).to eq('List of tags (comma-separated values)')
      end
    end

    context 'json type' do
      let(:parameter) do
        create(:parameter,
          prompt: prompt,
          parameter_type: 'json',
          description: 'Configuration object'
        )
      end

      it 'returns textarea input with JSON hint' do
        options = parameter.form_input_options
        expect(options[:type]).to eq('textarea')
        expect(options[:hint]).to eq('Configuration object (JSON format)')
      end
    end

    context 'without validation rules' do
      let(:parameter) { create(:parameter, prompt: prompt, parameter_type: 'integer') }

      it 'handles nil validation_rules gracefully' do
        options = parameter.form_input_options
        expect(options[:type]).to eq('number')
        expect(options).not_to have_key(:min)
        expect(options).not_to have_key(:max)
      end
    end
  end
end