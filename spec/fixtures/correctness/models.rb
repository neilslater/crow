# frozen_string_literal: true

module CorrectnessModels
  def self.models
    [scalar, buffers, array, residual, unavailable, families, sizes, dimensions]
  end

  def self.scalar
    { name: 'scalar', attributes: [
      { name: 'number', ruby_name: 'value', ctype: :int, ruby_write: true,
        init: { expr: '7', validate_min: -10, validate_max: 10 } },
      { name: 'hidden', ctype: :int, ruby_read: false },
      { name: 'data', ctype: :VALUE, ruby_write: true }
    ] }
  end

  def self.buffers
    { name: 'buffers', attributes: [
      { name: 'count', ctype: :int, init: { expr: '.' } },
      { name: 'first', ctype: :int, pointer: true, init: { size_expr: '.count', expr: '3' } },
      { name: 'second', ctype: :double, pointer: true, init: { size_expr: '%count', expr: '2.5' } }
    ], init_params: [{ name: 'count', ctype: :int }] }
  end

  def self.array
    { name: 'array', attributes: [
      { name: 'count', ctype: :int, init: { expr: '.' } },
      { name: 'data', ctype: :NARRAY_DOUBLE, init: { shape_exprs: ['$count'], expr: '4' } }
    ], init_params: [{ name: 'count', ctype: :int, init: { validate_min: 0, validate_max: 20 } }] }
  end

  def self.residual
    { name: 'residual', attributes: [
      { name: 'count', ctype: :int },
      { name: 'third', ctype: :int, store: false, init: { expr: '%second + 1' } },
      { name: 'second', ctype: :int, store: false, init: { expr: '%count + 1' } }
    ] }
  end

  def self.unavailable
    { name: 'unavailable', attributes: [
      { name: 'data', ctype: :NARRAY_FLOAT, init: { shape_exprs: ['$width'] } }
    ], init_params: [{ name: 'width', ctype: :int }] }
  end

  def self.sizes
    { name: 'sizes', attributes: [
      { name: 'data', ctype: :long, pointer: true, init: { size_expr: '$count * 2 / $divisor' } }
    ], init_params: [{ name: 'count', ctype: :ulong }, { name: 'divisor', ctype: :long }] }
  end

  def self.dimensions
    { name: 'dimensions', attributes: [
      { name: 'data', ctype: :NARRAY_DOUBLE, init: { shape_exprs: ['$count', '$count'] } }
    ], init_params: [{ name: 'count', ctype: :ulong }] }
  end

  def self.families
    { name: 'families', attributes: scalars + pointers + arrays }
  end

  def self.scalars
    %i[int uint long ulong char float double].map { |type| { name: "scalar_#{type}", ctype: type } }
  end

  def self.pointers
    %i[int uint long ulong float double char].map do |type|
      { name: "ptr_#{type}", ctype: type, pointer: true, ruby_read: type != :char,
        init: { size_expr: '2' } }
    end
  end

  def self.arrays
    %i[NARRAY_DOUBLE NARRAY_FLOAT NARRAY_INT16 NARRAY_INT32].map do |type|
      { name: type.to_s.downcase, ctype: type }
    end
  end
end
