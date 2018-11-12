require 'puppet/parameter'

module Puppet; module ResourceApi; end; end # predeclare the main module # rubocop:disable Style/Documentation,Style/ClassAndModuleChildren

# Class containing parameter functionality for ResourceApi.
class Puppet::ResourceApi::Parameter < Puppet::Parameter
  # This initialize takes arguments and sets up new parameter.
  # @param name the name used for reporting errors
  # @param type the type instance
  # @param definition the definition of the property
  # @param resource the resource instance which is passed to the parent class.
  def initialize(name, type, definiton, resource)
    @name = name
    @type = type
    @definiton = definiton
    super(resource: resource) # Pass resource to parent Puppet class.
  end

  # This method handles return of assigned value from parameter.
  # @return [type] the type value
  def value
    @value
  end

  # This method assigns value to the parameter and cleans value.
  # @param value the value to be set and clean
  # @return [type] the cleaned value
  def value=(value)
    @value = Puppet::ResourceApi::DataTypeHandling.mungify(
      @type,
      value,
      "#{@definiton[:name]}.#{name}",
      Puppet::ResourceApi.caller_is_resource_app?,
    )
  end

  # used internally
  # @returns the final mungified value of this parameter
  def rs_value
    @value
  end
end
