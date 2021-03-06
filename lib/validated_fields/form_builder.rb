
module ValidatedFields
  class FormBuilder < ActionView::Helpers::FormBuilder

    def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      options = setup_validation_options(method, options)
      super(method, options, checked_value, unchecked_value)
    end

    def password_field(method, options = {})
      options = setup_validation_options(method, options)
      super(method, options)
    end

    def text_area(method, options = {})
      options = setup_validation_options(method, options)
      super(method, options)
    end

    def text_field(method, options = {})
      options = setup_validation_options(method, options)
      super(method, options)
    end

    def radio_buttons(method, options, &block)
      options = setup_validation_options(method, options)
      options[:class].push("radio") if options[:class].is_a?(Array)

      @template.content_tag(:div, options, &block)
    end

    def check_boxes(method, options, &block)
      options = setup_validation_options(method, options)
      options[:class].push("checkboxes") if options[:class].is_a?(Array)

      @template.content_tag(:div, options, &block)
    end

    protected

      def setup_validation_options(attribute, options)
        if options[:validate].nil? || options[:validate] != true
          options.delete(:validate) unless options[:validate].nil?
          return options
        end

        validations     = 0  # counter
        validator_names = []

        validators = validators_for(@object, attribute)
        validators.each do |validator|
          next if skip_validation?(@object, validator.options)

          # if validator class is namespaced, extract class name only:
          validator_name = validator.class.to_s.split("::").last

          # check if validator has a helper implemented in ValidatedFields::Validators namespace:
          if ValidatedFields::Validators.const_defined?(validator_name)
            options = eval("ValidatedFields::Validators::#{validator_name}").prepare_options(validator, options)
            validator_names.push(validator_name.gsub(/Validator/, '').downcase) # e.g. PresenceValidator => presence

            validations += 1
          end
        end

        if validations > 0
          options[:class] ||= []
          options[:class]   = options[:class].split(" ") if !options[:class].is_a?(Array)
          options[:class].push("validated")

          options['data-validates'] = validator_names.uniq.join(' ') # list of all validators
        end

        options.delete(:validate)
        options
      end

      # Returns the list of all validators assigned to attribute
      def validators_for(object, attribute)
        object.class.validators_on(attribute)
      end

      def skip_validation?(object, voptions)
        if voptions[:if].present?
          return true if voptions[:if].is_a?(Proc)   && voptions[:if].call(object) == false
          return true if voptions[:if].is_a?(Symbol) && object.send(voptions[:if]) == false
        end

        if voptions[:unless].present?
          return true if voptions[:unless].is_a?(Proc)   && voptions[:unless].call(object) == true
          return true if voptions[:unless].is_a?(Symbol) && object.send(voptions[:unless]) == true
        end

        false
      end
  end
end
