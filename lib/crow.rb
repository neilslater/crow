# frozen_string_literal: true

# CROW is C Ruby Object Writer, a code generator that creates skeleton data structures for Ruby/C
# projects.
#
module Crow
  require_relative 'crow/version'
  require_relative 'crow/output_plan'
  require_relative 'crow/model_names'
  require_relative 'crow/model_validation'
  require_relative 'crow/dimension'
  require_relative 'crow/struct_attributes'
  require_relative 'crow/struct_contract'
  require_relative 'crow/spec_values'
  require_relative 'crow/libdef'
  require_relative 'crow/struct_class'
  require_relative 'crow/type_init'
  require_relative 'crow/typemap'
  require_relative 'crow/expression'
end
