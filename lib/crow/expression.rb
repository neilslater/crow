# frozen_string_literal: true

require 'ripper'

module Crow
  # This class represents template segments that can be assessed in context of attributes or arguments
  # available within a structure.
  #
  class Expression
    # @return [String] expression template before substitution
    attr_reader :text

    # @return [Array<Crow::TypeMap>] attributes available to the expression
    attr_reader :attributes

    # @return [Array<Crow::TypeMap>] initializer parameters available to the expression
    attr_reader :params

    # Creates an expression that may refer to struct attributes and initializer parameters.
    # @param [String] text expression template; `%name` refers to an attribute and `$name` to a parameter
    # @param [Array<Crow::TypeMap>] attributes attributes available to the expression
    # @param [Array<Crow::TypeMap>] params initializer parameters available to the expression
    def initialize(text, attributes, params = [])
      @text = text
      @attributes = attributes
      @params = params
    end

    # Renders the expression as C code, validating all attribute and parameter references.
    # @param [String] struct_var C variable used to access struct attributes
    # @return [String]
    # @raise [RuntimeError] if the expression references an unknown attribute or parameter
    def as_c_code(struct_var = attributes.first.parent_struct.short_name)
      code = c_sub_named_params(text, struct_var)
      c_sub_attributes(code, struct_var)
    end

    # Evaluates the expression using representative Ruby values for generated specs.
    # @return [Object]
    # @raise [RuntimeError] if the expression references an unknown attribute or parameter
    def as_ruby_test_value
      code = ruby_testval_named_params(text)
      code = ruby_testval_attributes(code)
      evaluate_arithmetic(code)
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

    def evaluate_arithmetic(code)
      body = Ripper.sexp(code)&.fetch(1, nil)
      raise ArgumentError, "Unsupported test expression: #{text}" unless body&.one?

      evaluate_node(body.first)
    end

    def evaluate_node(node)
      return evaluate_number(node) if %i[@int @float].include?(node.first)
      return evaluate_binary(node) if node.first == :binary
      return evaluate_unary(node) if node.first == :unary
      return evaluate_node(node.fetch(1).fetch(0)) if node.first == :paren

      raise ArgumentError, "Unsupported test expression: #{text}"
    end

    def evaluate_number(node)
      return Integer(node[1], 0) if node.first == :@int

      Float(node[1])
    end

    def evaluate_binary(node)
      left = evaluate_node(node[1])
      right = evaluate_node(node[3])
      operator = node[2]
      unless %i[+ - * / % ** << >> & | ^ < <= > >= == !=].include?(operator)
        raise ArgumentError, "Unsupported test expression: #{text}"
      end

      left.public_send(operator, right)
    end

    def evaluate_unary(node)
      value = evaluate_node(node[2])
      return +value if node[1] == :+@
      return -value if node[1] == :-@
      return ~value if node[1] == :~

      raise ArgumentError, "Unsupported test expression: #{text}"
    end

    def allowed_attr_names
      @allowed_attr_names ||= attributes.map(&:name)
    end

    def allowed_param_names
      @allowed_param_names ||= params.map(&:name)
    end
  end
end
