require 'puppet/parameter'

module Puppet; module ResourceApi; end; end # predeclare the main module # rubocop:disable Style/Documentation,Style/ClassAndModuleChildren

# Class containing read only parameter functionality for ResourceApi.
class Puppet::ResourceApi::ReadOnlyParameter < Puppet::Property
  # This initialize takes arguments and sets up new parameter.
  # @param name the name used for reporting errors
  # @param type the type instance
  # @param definition the definition of the property
  # @param resource the resource instance which is passed to the parent class.
  def initialize(name, type, definition, resource)
    @name = name
    @type = type
    @definition = definition
    super(resource: resource) # Pass resource to parent Puppet class.
  end

  # This method handles return of assigned value from parameter.
  # @return [type] the type value
  def value # rubocop:disable Style/TrivialAccessors
    @value
  end

  # This method raises error if the there is attempt to set value in parameter.
  # @return [Puppet::ResourceError] the error with information.
  def value=(value)
    raise Puppet::ResourceError,
          "Attempting to set `#{@name}` read_only attribute value to `#{value}`"
  end

  # used internally
  # @returns the final mungified value of this parameter
  def rs_value
    @value
  end
end
