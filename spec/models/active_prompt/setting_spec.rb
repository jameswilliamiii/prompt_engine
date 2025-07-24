require 'rails_helper'

module ActivePrompt
  RSpec.describe Setting, type: :model do
    describe 'table name' do
      it 'uses the correct table' do
        expect(described_class.table_name).to eq('active_prompt_settings')
      end
    end

    describe '.instance' do
      context 'when no settings exist' do
        before { described_class.destroy_all }

        it 'creates a new settings record' do
          expect { described_class.instance }.to change(described_class, :count).by(1)
        end

        it 'returns the settings instance' do
          settings = described_class.instance
          expect(settings).to be_a(described_class)
          expect(settings).to be_persisted
        end
      end

      context 'when settings already exist' do
        let!(:existing_settings) { described_class.create! }

        it 'returns the existing settings' do
          expect(described_class.instance).to eq(existing_settings)
        end

        it 'does not create a new record' do
          expect { described_class.instance }.not_to change(described_class, :count)
        end
      end
    end

    describe 'encrypted attributes' do
      let(:settings) { described_class.instance }

      it 'encrypts the openai_api_key' do
        settings.openai_api_key = 'sk-test-key'
        settings.save!

        # The encrypted value should be different from the plain text
        encrypted_value = described_class.connection.select_value(
          "SELECT openai_api_key FROM #{described_class.table_name} WHERE id = #{settings.id}"
        )
        expect(encrypted_value).not_to eq('sk-test-key')

        # But we can still read the decrypted value
        settings.reload
        expect(settings.openai_api_key).to eq('sk-test-key')
      end

      it 'encrypts the anthropic_api_key' do
        settings.anthropic_api_key = 'sk-ant-test-key'
        settings.save!

        # The encrypted value should be different from the plain text
        encrypted_value = described_class.connection.select_value(
          "SELECT anthropic_api_key FROM #{described_class.table_name} WHERE id = #{settings.id}"
        )
        expect(encrypted_value).not_to eq('sk-ant-test-key')

        # But we can still read the decrypted value
        settings.reload
        expect(settings.anthropic_api_key).to eq('sk-ant-test-key')
      end
    end

    describe '#masked_openai_api_key' do
      let(:settings) { described_class.instance }

      context 'when api key is present' do
        before { settings.update!(openai_api_key: 'sk-abc123xyz789') }

        it 'returns a masked version' do
          expect(settings.masked_openai_api_key).to eq('sk-...789')
        end
      end

      context 'when api key is nil' do
        before { settings.update!(openai_api_key: nil) }

        it 'returns nil' do
          expect(settings.masked_openai_api_key).to be_nil
        end
      end

      context 'when api key is short' do
        before { settings.update!(openai_api_key: 'short') }

        it 'returns asterisks' do
          expect(settings.masked_openai_api_key).to eq('*****')
        end
      end
    end

    describe '#masked_anthropic_api_key' do
      let(:settings) { described_class.instance }

      context 'when api key is present' do
        before { settings.update!(anthropic_api_key: 'sk-ant-api-key-123') }

        it 'returns a masked version' do
          expect(settings.masked_anthropic_api_key).to eq('sk-...123')
        end
      end

      context 'when api key is nil' do
        before { settings.update!(anthropic_api_key: nil) }

        it 'returns nil' do
          expect(settings.masked_anthropic_api_key).to be_nil
        end
      end
    end
  end
end
