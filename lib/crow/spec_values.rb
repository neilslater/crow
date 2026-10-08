# frozen_string_literal: true

module Crow
  # Computes conservative, shared fixtures for generated Ruby specs.
  module SpecValues
    # Representative positional constructor arguments.
    # @return [Array<Object>]
    def spec_arguments
      init_params.map { |param| representative(param) }
    end

    # An explanation when a constructor fixture cannot be safely inferred.
    # @return [String, nil]
    def spec_fixture_error
      spec_arguments
      nil
    rescue ArgumentError => e
      e.message
    end

    # Independent literal expectation for an exposed scalar, when derivable.
    # @param field [TypeMap] scalar field
    # @return [String] Ruby literal
    def spec_expected(field)
      expected_attributes.fetch(field.name).inspect
    end

    # Reports an unsupported automatic field expectation without executing C.
    # @param field [TypeMap] scalar field
    # @return [String, nil]
    def spec_expectation_error(field)
      spec_expected(field)
      nil
    rescue ArgumentError, KeyError => e
      e.message
    end

    private

    def expected_attributes
      parameters = init_params.map(&:name).zip(spec_arguments).to_h
      values = simple_attributes.to_h { |attr| [attr.name, literal_value(attr.default)] }
      simple_attributes_with_init.each { |attr| update_expected(attr, parameters, values) }
      values
    end

    def update_expected(attr, parameters, values)
      expression = attr.init.expr == '.' ? "$#{attr.name}" : attr.init.expr
      values[attr.name] = fixture_expression(expression, parameters, values)
    end

    def fixture_expression(expression, parameters, values)
      code = expression.gsub(/\$([a-zA-Z0-9_]+)/) { parameters.fetch(Regexp.last_match(1)).inspect }
      code = code.gsub(/%([a-zA-Z0-9_]+)/) { values.fetch(Regexp.last_match(1)).inspect }
      literal_value(code)
    end

    def representative(param)
      raise ArgumentError, "Supply a fixture for #{param.name}" if param.pointer || param.narray?
      return nil if param.ctype == :VALUE

      lower, upper = representative_bounds(param)
      value = [lower || 1, upper].compact.min
      value = value.ceil if Dimension::TYPES.include?(param.ctype)
      validate_representative(param, value, upper)
      value
    end

    def representative_bounds(param)
      bounds = [param.init.validate_min, param.init.validate_max]
      raise ArgumentError, "Supply a fixture for #{param.name} bounds" unless bounds.compact.all?(Numeric)

      bounds
    end

    def validate_representative(param, value, upper)
      return unless (upper && value > upper) || (%i[uint ulong].include?(param.ctype) && value.negative?)

      raise ArgumentError, "No representative value for #{param.name}"
    end

    def literal_value(expression)
      special = { 'Qnil' => nil, 'Qtrue' => true, 'Qfalse' => false, 'nil' => nil, 'true' => true, 'false' => false }
      return special[expression] if special.key?(expression)

      normalized = expression.gsub(/(?<=\d)[fFlL]\b/, '')
      Expression.new(normalized, [], []).as_ruby_test_value
    end
  end
end
