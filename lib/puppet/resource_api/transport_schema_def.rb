require 'puppet/resource_api/base_type_definition'
# Provides accessor methods for the type being provided
class Puppet::ResourceApi::TransportSchemaDef < Puppet::ResourceApi::BaseTypeDefinition
  def initialize(definition)
    raise Puppet::DevError, 'TransportSchemaDef requires definition to be a Hash' unless definition.is_a?(Hash)
    super(definition, :connection_info)
  end
end
