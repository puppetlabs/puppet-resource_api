require 'puppet/resource_api/base_type_definition'
# Provides accessor methods for the type being provided
class Puppet::ResourceApi::TypeDefinition < Puppet::ResourceApi::BaseTypeDefinition
  def initialize(definition)
    raise Puppet::DevError, 'TypeDefinition requires definition to be a Hash' unless definition.is_a?(Hash)
    super(definition, :attributes)
  end

  def ensurable?
    attributes.key?(:ensure)
  end

  # rubocop complains when this is named has_feature?
  def feature?(feature)
    supported = (definition[:features] && definition[:features].include?(feature))
    if supported
      Puppet.debug("#{definition[:name]} supports `#{feature}`")
    else
      Puppet.debug("#{definition[:name]} does not support `#{feature}`")
    end
    supported
  end
end
