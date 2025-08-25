import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["contentField", "parametersSection", "parametersList"]
  static values = { existingParameters: Array }

  connect() {
    // Detect variables on page load
    this.detectVariables()
  }

  detectVariables() {
    const content = this.contentFieldTarget.value
    const variablePattern = /\{\{([a-zA-Z_][a-zA-Z0-9_]*(?:\.[a-zA-Z_][a-zA-Z0-9_]*)*)\}\}/g
    const matches = [...content.matchAll(variablePattern)]
    const uniqueVariables = [...new Set(matches.map(match => match[1]))]
    
    if (uniqueVariables.length > 0) {
      this.parametersSectionTarget.style.display = 'block'
      this.updateParametersDisplay(uniqueVariables)
    } else {
      this.parametersSectionTarget.style.display = 'none'
    }
  }

  updateParametersDisplay(variables) {
    this.parametersListTarget.innerHTML = ''
    
    // Add fields for parameters that should be kept
    variables.forEach((variable, index) => {
      const existingParam = this.existingParametersValue.find(p => p.name === variable)
      const parameterItem = this.createParameterItem(variable, index, existingParam)
      this.parametersListTarget.appendChild(parameterItem)
    })
    
    // Add hidden fields to destroy parameters that are no longer in content
    let destroyIndex = variables.length
    this.existingParametersValue.forEach(param => {
      if (!variables.includes(param.name)) {
        const destroyField = document.createElement('div')
        destroyField.style.display = 'none'
        destroyField.innerHTML = `
          <input type="hidden" name="prompt[parameters_attributes][${destroyIndex}][id]" value="${param.id}">
          <input type="hidden" name="prompt[parameters_attributes][${destroyIndex}][_destroy]" value="1">
        `
        this.parametersListTarget.appendChild(destroyField)
        destroyIndex++
      }
    })
  }

  createParameterItem(variableName, index, existingData) {
    const div = document.createElement('div')
    div.className = 'parameter-item'
    div.innerHTML = `
      <div class="parameter-field">
        <label>Name</label>
        <span class="parameter-name">${variableName}</span>
        <input type="hidden" name="prompt[parameters_attributes][${index}][name]" value="${variableName}">
        ${existingData ? `<input type="hidden" name="prompt[parameters_attributes][${index}][id]" value="${existingData.id}">` : ''}
      </div>
      
      <div class="parameter-field">
        <label>Type</label>
        <select name="prompt[parameters_attributes][${index}][parameter_type]" class="form__select form__select--small">
          <option value="string" ${existingData?.parameter_type === 'string' ? 'selected' : ''}>String</option>
          <option value="number" ${existingData?.parameter_type === 'number' ? 'selected' : ''}>Number</option>
          <option value="boolean" ${existingData?.parameter_type === 'boolean' ? 'selected' : ''}>Boolean</option>
          <option value="array" ${existingData?.parameter_type === 'array' ? 'selected' : ''}>Array</option>
          <option value="object" ${existingData?.parameter_type === 'object' ? 'selected' : ''}>Object</option>
        </select>
      </div>
      
      <div class="parameter-field">
        <label>Required</label>
        <div class="parameter-checkbox">
          <input type="hidden" name="prompt[parameters_attributes][${index}][required]" value="0">
          <input type="checkbox" 
                 name="prompt[parameters_attributes][${index}][required]" 
                 value="1"
                 ${existingData?.required !== false ? 'checked' : ''}>
        </div>
      </div>
      
      <div class="parameter-field">
        <label>Default Value</label>
        <input type="text" 
               name="prompt[parameters_attributes][${index}][default_value]" 
               class="form__input form__input--small"
               placeholder="Optional"
               value="${existingData?.default_value || ''}">
      </div>
      
      <div class="parameter-field">
        <label>Description</label>
        <input type="text" 
               name="prompt[parameters_attributes][${index}][description]" 
               class="form__input form__input--small"
               placeholder="Optional"
               value="${existingData?.description || ''}">
      </div>
    `
    return div
  }
}