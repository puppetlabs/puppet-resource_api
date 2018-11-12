# Provides accessor methods for the type being provided
class Puppet::ResourceApi::TypeDefinition
  attr_reader :definition

  def initialize(definition)
    raise Puppet::DevError, 'TypeDefinition requires definition to be a Hash' unless definition.is_a?(Hash)
    @definition = definition
  end

  def name
    @definition[:name]
  end

  def attributes
    @definition[:attributes]
  end

  def ensurable?
    @definition[:attributes].key?(:ensure)
  end

  def namevars
    @namevars ||= @definition[:attributes].select { |_name, options|
      options.key?(:behaviour) && options[:behaviour] == :namevar
    }.keys
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

  # validates a resource hash against its type schema
  def check_schema(resource)
    namevars.each do |namevar|
      if resource[namevar].nil?
        raise Puppet::ResourceError, "`#{name}.get` did not return a value for the `#{namevar}` namevar attribute"
      end
    end

    message = "Provider returned data that does not match the Type Schema for `#{name}[#{resource[namevars.first]}]`"

    rejected_keys = check_schema_keys(resource) # removes bad keys
    bad_values = check_schema_values(resource)

    unless rejected_keys.empty?
      message += "\n Unknown attribute:\n"
      rejected_keys.each { |key, _value| message += "    * #{key}\n" }
    end
    unless bad_values.empty?
      message += "\n Value type mismatch:\n"
      bad_values.each { |key, value| message += "    * #{key}: #{value}\n" }
    end

    return if rejected_keys.empty? && bad_values.empty?

    if Puppet.settings[:strict] == :off
      Puppet.debug(message)
    elsif Puppet.settings[:strict] == :warning
      Puppet::ResourceApi.warning_count += 1
      Puppet.warning(message) if Puppet::ResourceApi.warning_count <= 100 # maximum number of schema warnings to display in a run
    elsif Puppet.settings[:strict] == :error
      raise Puppet::DevError, message
    end
  end

  # Returns an array of keys that where not found in the type schema
  # Modifies the resource passed in, leaving only valid attributes
  def check_schema_keys(resource)
    rejected = []
    resource.reject! { |key| rejected << key if key != :title && attributes.key?(key) == false }
    rejected
  end

  # Returns a hash of keys and values that are not valid
  # does not modify the resource passed in
  def check_schema_values(resource)
    bad_vals = {}
    resource.each do |key, value|
      next unless attributes[key]
      type = Puppet::ResourceApi::DataTypeHandling.parse_puppet_type(
        key,
        attributes[key][:type],
      )
      error_message = Puppet::ResourceApi::DataTypeHandling.try_validate(
        type,
        value,
        '',
      )
      bad_vals[key] = value unless error_message.nil?
    end
    bad_vals
  end
end
