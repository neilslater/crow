# frozen_string_literal: true

module Crow
  # Derived allocation and restoration contracts shared by generated templates.
  module StructContract
    # Allocation expressions in constructor context.
    # @return [Array<String>]
    def storage_dimensions
      alloc_attributes.map { |field| pointer_dimension(field) } + narray_attributes.flat_map do |field|
        field.init.normalized_shapes
      end
    end

    # Resolves the pointer-size dot shorthand for construction.
    # @param field [TypeMap] pointer field
    # @return [String]
    def pointer_dimension(field)
      field.init.size_expr.to_s.sub(/\A\./, '$')
    end

    # Emits a checked dimension conversion using the generated struct helper.
    # @param text [String] dimension expression
    # @param variable [String] struct pointer
    # @return [String]
    def dimension_c(text, variable = short_name)
      "#{short_name}__dimension(#{Dimension.new(text, self).ruby_c(variable)})"
    end

    # Parameters recoverable exactly from persisted fields.
    # @return [Hash<String, TypeMap>]
    def restored_params
      init_params.to_h do |param|
        field = stored_attributes.find do |attr|
          exact_parameter_field?(attr, param)
        end
        [param.name, field]
      end.compact
    end

    # Orders residual scalar reconstruction, or explains why restoration cannot be generated.
    # @return [Array<TypeMap>]
    def restore_order
      order_residuals(non_stored_attributes.reject { |field| field.pointer || field.narray? })
    end

    # Reason automatic restoration is unavailable, otherwise nil.
    # @return [String, nil]
    def restoration_error
      restore_order
      storage_dimensions.each { |text| verify_restore_expression(text) }
      non_stored_attributes.select { |field| field.pointer || field.narray? }.each do |field|
        verify_restore_expression(field.init.expr)
      end
      nil
    rescue ArgumentError => e
      e.message
    end

    # Expression for a reconstructed non-stored scalar.
    # @param field [TypeMap] model field
    # @return [String]
    def restore_expression(field)
      expression = field.init.expr || field.default
      expression == '.' ? "$#{field.name}" : expression
    end

    # Renders a restoration scalar expression with recovered parameter references.
    # @param field [TypeMap] residual scalar
    # @return [String]
    def restore_scalar_c(field)
      text = restore_expression(field)
      return text if /\A(?:Qnil|Qtrue|Qfalse|[-+]?\d+(?:\.\d+)?[fFlL]?)\z/.match?(text)

      field.class.ruby_to_c(Dimension.new(text, self).ruby_c(short_name))
    end

    private

    def exact_parameter_field?(attr, param)
      return false if attr.pointer || attr.narray? || attr.ctype != param.ctype

      attr.init.expr == "$#{param.name}" || (attr.init.expr == '.' && attr.name == param.name)
    end

    def order_residuals(pending, available = stored_attributes.map(&:name))
      return [] if pending.empty?

      field = pending.find { |attr| (restore_expression(attr).scan(/%([a-zA-Z0-9_]+)/).flatten - available).empty? }
      raise ArgumentError, 'cyclic residual scalar dependencies' unless field

      verify_restore_expression(restore_expression(field))
      [field] + order_residuals(pending - [field], available + [field.name])
    end

    def verify_restore_expression(text)
      raise ArgumentError, 'missing restoration expression' unless text
      return if /\A(?:Qnil|Qtrue|Qfalse|[-+]?\d+(?:\.\d+)?[fFlL]?)\z/.match?(text)

      expression = Dimension.new(text, self)
      missing = expression.references.grep(/\A\$/).map { |ref| ref[1..] } - restored_params.keys
      raise ArgumentError, "unavailable restoration parameters: #{missing.join(', ')}" unless missing.empty?
    end
  end
end
