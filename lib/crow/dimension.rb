# frozen_string_literal: true

require 'ripper'

module Crow
  # Parses the deliberately limited integer language used for allocation extents.
  class Dimension
    # Integral model types usable in dimension expressions.
    TYPES = %i[int uint long ulong char].freeze

    # Creates and validates an expression without executing supplied code.
    # @param text [String] expression
    # @param struct [StructClass] containing model
    def initialize(text, struct)
      @text = text
      @struct = struct
      @references = {}
      code = text.gsub(/[%$][a-zA-Z0-9_]+/) { |ref| reference(ref) }
      body = Ripper.sexp(code)&.fetch(1, nil)
      raise ArgumentError, "Unsupported dimension: #{text}" unless body&.one?

      @tree = body.first
      emit(@tree, 'item')
    end

    # Attribute/parameter references used by this expression.
    # @return [Array<String>]
    def references
      @references.values
    end

    # Emits Ruby Integer arithmetic so intermediate C arithmetic cannot overflow.
    # @param variable [String] native struct pointer name
    # @return [String] C expression returning a Ruby Integer
    def ruby_c(variable)
      emit(@tree, variable)
    end

    private

    def reference(ref)
      mappings = ref.start_with?('%') ? @struct.attributes : @struct.init_params
      field = mappings.find { |mapping| mapping.name == ref[1..] }
      unless field && TYPES.include?(field.ctype) && !field.pointer
        raise ArgumentError, "Dimension requires an integral reference: #{ref}"
      end

      key = "crow_ref_#{@references.length}"
      @references[key] = ref
      key
    end

    def emit(node, variable)
      case node.first
      when :@int then "rb_cstr_to_inum(#{node[1].inspect}, 0, 1)"
      when :vcall then emit_reference(node[1][1], variable)
      when :paren then emit_parentheses(node, variable)
      when :binary then emit_binary(node, variable)
      when :unary then emit_unary(node, variable)
      else raise ArgumentError, "Unsupported dimension: #{@text}"
      end
    end

    def emit_parentheses(node, variable)
      raise ArgumentError, "Unsupported dimension: #{@text}" unless node[1].one?

      emit(node[1].first, variable)
    end

    def emit_reference(key, variable)
      ref = @references.fetch(key) { raise ArgumentError, "Unsupported dimension: #{@text}" }
      mappings = ref.start_with?('%') ? @struct.attributes : @struct.init_params
      field = mappings.find { |mapping| mapping.name == ref[1..] }
      value = ref.start_with?('%') ? "#{variable}->#{field.name}" : field.name
      field.class.c_to_ruby(value)
    end

    def emit_binary(node, variable)
      op = node[2]
      raise ArgumentError, "Unsupported dimension: #{@text}" unless %i[+ - * /].include?(op)

      left = emit(node[1], variable)
      right = emit(node[3], variable)
      return "#{@struct.short_name}__divide(#{left}, #{right})" if op == :/

      "rb_funcall(#{left}, rb_intern(#{op.to_s.inspect}), 1, #{right})"
    end

    def emit_unary(node, variable)
      op = node[1]
      raise ArgumentError, "Unsupported dimension: #{@text}" unless %i[+@ -@].include?(op)

      "rb_funcall(#{emit(node[2], variable)}, rb_intern(#{op.to_s.inspect}), 0)"
    end
  end
end
