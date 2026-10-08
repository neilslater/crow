# frozen_string_literal: true

module Crow
  # Validates the mutable generator model immediately before rendering output.
  module ModelValidation
    extend ModelNames

    # Validates project-wide names and each contained struct.
    # @param lib [LibDef] project model
    def self.library(lib)
      identifier(lib.short_name)
      identifier(lib.module_name)
      constant(lib.module_name)
      %i[short_name struct_name rb_class_name].each { |key| unique(lib.structs.map(&key), key) }
      lib.structs.each { |struct| structure(struct) }
    end

    # Validates an independently writable struct model.
    # @param struct [StructClass] struct model
    def self.structure(struct)
      validate_names(struct)
      (struct.attributes + struct.init_params).each { |field| mapping(field) }
      struct.attributes.each { |field| attribute(field) }
      validate_dimensions(struct)
    rescue ArgumentError => e
      raise ArgumentError, "#{struct.lib_short_name}/#{struct.short_name}: #{e.message}"
    end

    def self.validate_names(struct)
      [struct.short_name, struct.struct_name, struct.lib_short_name, struct.rb_class_name].each do |name|
        identifier(name)
      end
      constant(struct.lib_module_name)
      constant(struct.rb_class_name)
      validate_field_names(struct)
      unique(exposed_methods(struct) + ModelNames::METHODS, 'Ruby method')
    end
    private_class_method :validate_names

    def self.validate_field_names(struct)
      unique(struct.attributes.map(&:name), 'field')
      unique(struct.init_params.map(&:name) + [struct.short_name], 'parameter or native receiver')
    end
    private_class_method :validate_field_names

    def self.exposed_methods(struct)
      struct.attributes.flat_map do |field|
        [field.ruby_read ? field.ruby_name : nil, field.ruby_write ? "#{field.ruby_name}=" : nil].compact
      end
    end
    private_class_method :exposed_methods

    def self.mapping(field)
      identifier(field.name)
      raise ArgumentError, "#{field.name}: crow_ is reserved for native bookkeeping" if field.name.start_with?('crow_')

      if field.pointer && (field.narray? || field.ctype == :VALUE)
        raise ArgumentError, "#{field.name}: pointer is unsupported for #{field.ctype}; remove pointer: true"
      end

      validate_bounds(field)
    end
    private_class_method :mapping

    def self.validate_bounds(field)
      bounds = [field.init.validate_min, field.init.validate_max]
      return unless bounds.all?(Numeric) && bounds.first > bounds.last

      raise ArgumentError, "#{field.name}: validate_min exceeds validate_max"
    end
    private_class_method :validate_bounds

    def self.attribute(field)
      validate_reader_name(field)
      pointer(field) if field.pointer
      field.init.normalized_shapes if field.narray?
      if field.ruby_write && (field.pointer || field.narray?)
        raise ArgumentError, "#{field.name}: ruby_write unsupported; use ruby_write: false"
      end

      validate_expression(field)
    end
    private_class_method :attribute

    def self.pointer(field)
      raise ArgumentError, "#{field.name}: supply size_expr" if field.init.size_expr.to_s.empty?
      raise ArgumentError, "#{field.name}: pointer requires store: false" if field.store
      return unless field.ctype == :char && field.ruby_read

      raise ArgumentError, "#{field.name}: char pointer requires ruby_read: false"
    end
    private_class_method :pointer

    def self.validate_expression(field)
      return unless field.init.expr

      field.init_expr_c(init_context: !field.pointer && !field.narray?)
    rescue RuntimeError => e
      raise ArgumentError, "#{field.name}: #{e.message}"
    end
    private_class_method :validate_expression

    def self.validate_dimensions(struct)
      refs = struct.storage_dimensions.flat_map { |text| Dimension.new(text, struct).references }
      names = refs.grep(/\A%/).map { |ref| ref[1..] }
      names += refs.grep(/\A\$/).filter_map { |ref| struct.restored_params[ref[1..]]&.name }
      validate_dependencies(struct, names)
    end

    private_class_method :validate_dimensions

    def self.attribute_dependencies(field)
      field.init.expr.to_s.scan(/%([a-zA-Z0-9_]+)/).flatten
    end
    private_class_method :attribute_dependencies

    def self.validate_dependencies(struct, pending, seen = [])
      return if pending.empty?

      name, *rest = pending
      return validate_dependencies(struct, rest, seen) if seen.include?(name)

      field = struct.attributes.find { |item| item.name == name }
      raise ArgumentError, "#{name}: storage dependency requires ruby_write: false" if field.ruby_write

      validate_dependencies(struct, rest + attribute_dependencies(field), seen + [name])
    end
    private_class_method :validate_dependencies
  end
end
