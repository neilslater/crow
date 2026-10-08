# frozen_string_literal: true

module Crow
  # Classifies fields by their generated storage and binding responsibilities.
  module StructAttributes
    # Whether any of the attributes are NArray objects.
    # @return [Boolean]
    def any_narray?
      @attributes.any?(&:narray?)
    end

    # List of attributes which contain NArray objects.
    # @return [Array<Crow::TypeMap>]
    def narray_attributes
      @attributes.select(&:narray?)
    end

    # List of attributes which should be handled by to_h and from_h.
    # @return [Array<Crow::TypeMap>]
    def stored_attributes
      @attributes.select(&:store)
    end

    # Attributes excluded from generated persistence helpers.
    # @return [Array<Crow::TypeMap>]
    def non_stored_attributes
      @attributes.reject(&:store)
    end

    # Whether any attribute requires separately allocated storage.
    # @return [Boolean]
    def any_alloc?
      @attributes.any?(&:needs_alloc?)
    end

    # Whether generated initialization code is required.
    # @return [Boolean]
    def needs_init?
      !!(any_narray? || any_alloc? || init_params.any? || simple_attributes_with_init.any?)
    end

    # Whether initialization must iterate over allocated or NArray data.
    # @return [Boolean]
    def needs_init_iterators?
      !!(any_narray? || any_alloc?)
    end

    # Attributes whose generated C representation requires allocation.
    # @return [Array<Crow::TypeMap>]
    def alloc_attributes
      @attributes.select(&:needs_alloc?)
    end

    # Scalar attributes that require neither allocation nor NArray handling.
    # @return [Array<Crow::TypeMap>]
    def simple_attributes
      @attributes.reject { |a| a.needs_alloc? || a.narray? }
    end

    # Scalar attributes that have an initialization expression.
    # @return [Array<Crow::TypeMap>]
    def simple_attributes_with_init
      @attributes.reject { |a| a.needs_alloc? || a.narray? }.select(&:needs_init?)
    end

    # Attributes for which generated specs can construct simple test values.
    # @return [Array<Crow::TypeMap>]
    def testable_attributes
      simple_attributes.select(&:ruby_read)
    end
  end
end
