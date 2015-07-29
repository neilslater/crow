module Crow
  class Expression
    attr_reader :text, :attributes, :params

    def initialize text, attributes, params = []
      @text = text
      @attributes = attributes
      @params = params
    end

    def as_c_code struct_var = attributes.first.parent_struct.short_name
      # Substitute named params
      code = text.gsub( /\$[a-zA-Z0-9_]+/ ) do |matched|
        param_name = matched[1,100]
        allowed_names = params.map(&:name)
        unless allowed_names.include?(param_name)
          raise "Param #{param_name} not found (#{struct_var}), must be one of #{allowed_names.join(', ')}"
        end
        param_name
      end

      # Substitute attributes
      code.gsub( /\%[a-zA-Z0-9_]+/ ) do |matched|
        attr_name = matched[1,100]
        allowed_names = attributes.map(&:name)
        found_attr = attributes.find { |x| x.name == attr_name }
        unless allowed_names.include?(attr_name)
          raise "Attribute #{attr_name} not found (#{struct_var}), must be one of #{allowed_names.join(', ')}"
        end
        "#{struct_var}->#{attr_name}"
      end
    end
  end
end
