# frozen_string_literal: true

module Crow
  # This class represents template segments that can be assessed in context of attributes or arguments
  # available within a structure.
  #
  class Expression
    attr_reader :text, :attributes, :params

    def initialize(text, attributes, params = [])
      @text = text
      @attributes = attributes
      @params = params
    end

    def as_c_code(struct_var = attributes.first.parent_struct.short_name)
      code = c_sub_named_params(text, struct_var)
      c_sub_attributes(code, struct_var)
    end

    def as_ruby_test_value
      code = ruby_testval_named_params(text)
      ruby_testval_attributes(code)
      # Evil
      eval code
    end

    private

    def c_sub_named_params(code, struct_var)
      code.gsub(/\$[a-zA-Z0-9_]+/) do |matched|
        param_name = matched[1, 100]
        unless allowed_param_names.include?(param_name)
          raise "Param #{param_name} not found (#{struct_var}), must be one of #{allowed_param_names.join(', ')}"
        end

        param_name
      end
    end

    def c_sub_attributes(code, struct_var)
      code.gsub(/%[a-zA-Z0-9_]+/) do |matched|
        attr_name = matched[1, 100]
        unless allowed_attr_names.include?(attr_name)
          raise "Attribute #{attr_name} not found (#{struct_var}), must be one of #{allowed_attr_names.join(', ')}"
        end

        "#{struct_var}->#{attr_name}"
      end
    end

    def ruby_testval_named_params(code)
      code.gsub(/\$[a-zA-Z0-9_]+/) do |matched|
        param_name = matched[1, 100]
        unless (param = params.find { |x| x.name == param_name })
          raise "Param #{param_name} not found (#{text}), must be one of #{allowed_param_names.join(', ')}"
        end

        [param.default.to_i, param.min_valid].max.to_s
      end
    end

    def ruby_testval_attributes(code)
      code.gsub(/%[a-zA-Z0-9_]+/) do |matched|
        attr_name = matched[1, 100]
        unless (attr = attributes.find { |x| x.name == attr_name })
          raise "Attribute #{attr_name} not found (#{text}), must be one of #{allowed_attr_names.join(', ')}"
        end

        [attr.default.to_i, attr.min_valid].max.to_s
      end
    end

    def allowed_attr_names
      @allowed_attr_names ||= attributes.map(&:name)
    end

    def allowed_param_names
      @allowed_param_names ||= params.map(&:name)
    end
  end
end
