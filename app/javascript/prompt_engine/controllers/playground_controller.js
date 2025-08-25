import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["providerSelect", "apiKeyField", "helpText", "useSavedKeysCheckbox"]
  static values = { 
    anthropicKey: String, 
    openaiKey: String,
    settingsPath: String,
    hasSavedKeys: Boolean
  }

  connect() {
    this.updateApiKeyOnLoad()
  }

  providerChanged() {
    this.updateApiKey()
  }

  toggleSavedKeys() {
    this.updateApiKey()
  }

  updateApiKeyOnLoad() {
    // Set initial API key based on current provider selection
    this.updateApiKey()
  }

  updateApiKey() {
    const selectedProvider = this.providerSelectTarget.value
    const useSavedKeys = this.hasSavedKeysValue && this.hasUseSavedKeysCheckboxTarget && this.useSavedKeysCheckboxTarget.checked
    
    if (useSavedKeys && selectedProvider === 'anthropic' && this.anthropicKeyValue) {
      this.apiKeyFieldTarget.value = this.anthropicKeyValue
      this.apiKeyFieldTarget.placeholder = 'Using saved API key'
      this.updateHelpText(true)
    } else if (useSavedKeys && selectedProvider === 'openai' && this.openaiKeyValue) {
      this.apiKeyFieldTarget.value = this.openaiKeyValue
      this.apiKeyFieldTarget.placeholder = 'Using saved API key'
      this.updateHelpText(true)
    } else {
      this.apiKeyFieldTarget.value = ''
      this.apiKeyFieldTarget.placeholder = 'Enter your API key'
      this.updateHelpText(false)
    }
  }

  updateHelpText(hasStoredKey) {
    const settingsLink = `<a href="${this.settingsPathValue}" class="link">Change in settings</a>`
    const saveLink = `<a href="${this.settingsPathValue}" class="link">Save in settings</a>`
    
    if (hasStoredKey) {
      this.helpTextTarget.innerHTML = `Using saved API key from settings. ${settingsLink}`
    } else {
      this.helpTextTarget.innerHTML = `Your API key will not be stored. ${saveLink}`
    }
  }
}