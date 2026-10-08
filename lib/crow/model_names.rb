# frozen_string_literal: true

module Crow
  # Shared validation for generated identifiers and namespaces.
  module ModelNames
    # C keywords and private generated names cannot name model entities.
    KEYWORDS = %w[auto break case char const continue default do double else enum extern float for goto if int long
                  register return short signed sizeof static struct switch typedef union unsigned void volatile while
                  inline restrict _Bool _Complex _Imaginary _Alignas _Alignof _Atomic _Generic _Noreturn _Static_assert
                  _Thread_local].freeze
    # Ruby methods owned by generated lifecycle bindings.
    METHODS = %w[initialize initialize_copy to_h from_h].freeze

    # Checks a generated C identifier.
    # @param name [String] identifier
    def identifier(name)
      return if /\A[a-zA-Z_][a-zA-Z0-9_]*\z/.match?(name) && !KEYWORDS.include?(name)

      raise ArgumentError, "Invalid or reserved C identifier #{name.inspect}; choose a distinct identifier"
    end

    # Checks a generated Ruby constant path.
    # @param name [String] constant name
    def constant(name)
      return if /\A[A-Z][a-zA-Z0-9_]*(?:::[A-Z][a-zA-Z0-9_]*)*\z/.match?(name)

      raise ArgumentError, "Invalid Ruby constant #{name.inspect}"
    end

    # Rejects duplicate names in one namespace.
    # @param names [Array<String>] emitted names
    # @param context [Object] diagnostic namespace
    def unique(names, context)
      return if names.uniq.length == names.length

      raise ArgumentError, "Duplicate #{context}: #{names.join(', ')}"
    end

    # Validates an exposed Ruby field name.
    # @param field [TypeMap] model field
    def validate_reader_name(field)
      return unless field.ruby_read || field.ruby_write
      return if /\A[a-zA-Z_][a-zA-Z0-9_]*\z/.match?(field.ruby_name)

      raise ArgumentError, "#{field.name}: invalid ruby_name"
    end
  end
end
