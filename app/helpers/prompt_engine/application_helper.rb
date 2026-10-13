module PromptEngine
  module ApplicationHelper
    # Keeps a model missing from the catalog selectable, so saving the form doesn't blank it.
    def model_options_for(current_model)
      models = PromptEngine.config.models
      options = models.map { |id, entry| model_option(entry[:label] || id, id, entry) }
      return options if current_model.blank? || models.key?(current_model)

      options << model_option("#{current_model} (not configured)", current_model, nil)
    end

    def model_option(label, id, entry)
      settings = PromptEngine.config.model_settings(id, entry)
      [ label, id, { data: {
        supports_temperature: settings[:supports_temperature] != false,
        supports_effort: settings[:supports_effort] == true
      } } ]
    end

    # The value a request to the prompt's model carries, or nil when the model doesn't take it.
    def sent_setting(prompt, attribute)
      supported = case attribute
      when :temperature then PromptEngine.config.supports_temperature?(prompt.model)
      when :effort then PromptEngine.config.supports_effort?(prompt.model)
      else raise ArgumentError, "No model capability for #{attribute}"
      end
      prompt.public_send(attribute) if supported
    end

    def setting_label(prompt, attribute)
      value = prompt.public_send(attribute)
      return "Default" if value.nil?

      sent_setting(prompt, attribute).nil? ? "#{value} (not sent to this model)" : value.to_s
    end

    def usage_variables(blank: "")
      return blank if @prompt.parameters.none?

      pairs = @prompt.parameters.ordered.each_with_index.map do |param, index|
        "  #{param.name}: #{(param.example_value.presence || "value#{index + 1}").inspect}"
      end
      ", {\n#{pairs.join(",\n")}\n}"
    end
  end
end
