# Provides accessor methods for the type being provided
module Puppet::ResourceApi
  # pre-declare class
  class BaseTypeDefinition; end

  # RSAPI Resource Type
  class TypeDefinition < BaseTypeDefinition
    def initialize(definition)
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

    def validate_schema(definition, attr_key)
      super(definition, attr_key)
      [:title, :provider, :alias, :audit, :before, :consume, :export, :loglevel, :noop, :notify, :require, :schedule, :stage, :subscribe, :tag].each do |name|
        raise Puppet::DevError, 'must not define an attribute called `%{name}`' % { name: name.inspect } if definition[attr_key].key? name
      end
      if definition.key?(:title_patterns) && !definition[:title_patterns].is_a?(Array)
        raise Puppet::DevError, '`:title_patterns` must be an array, not `%{other_type}`' % { other_type: definition[:title_patterns].class }
      end

      Puppet::ResourceApi::DataTypeHandling.validate_ensure(definition)

      definition[:features] ||= []
      supported_features = %w[supports_noop canonicalize remote_resource simple_get_filter].freeze
      unknown_features = definition[:features] - supported_features
      Puppet.warning("Unknown feature detected: #{unknown_features.inspect}") unless unknown_features.empty?

      # store the validated definition
      @definition = definition
    end
  end

  # RSAPI Transport schema
  class TransportSchemaDef < BaseTypeDefinition
    def initialize(definition)
      super(definition, :connection_info)
    end
  end

  # Base RSAPI schema Object
  class BaseTypeDefinition
    attr_reader :definition, :attributes

    def initialize(definition, attr_key)
      @data_type_cache = {}
      validate_schema(definition, attr_key)
    end

    def name
      @definition[:name]
    end

    def namevars
      @namevars ||= attributes.select { |_name, options|
        options.key?(:behaviour) && options[:behaviour] == :namevar
      }.keys
    end

    def validate_schema(definition, attr_key)
      raise Puppet::DevError, '%{type_class} must be a Hash, not `%{other_type}`' % { type_class: self.class.name, other_type: definition.class } unless definition.is_a?(Hash)
      @attributes = definition[attr_key]
      raise Puppet::DevError, '%{type_class} must have a name' % { type_class: self.class.name } unless definition.key? :name
      raise Puppet::DevError, '%{type_class} must have `%{attr_key}`' % { type_class: self.class.name, attrs: attr_key } unless definition.key? attr_key
      unless attributes.is_a?(Hash)
        raise Puppet::DevError, '`%{name}.%{attrs}` must be a hash, not `%{other_type}`' % {
          name: definition[:name], attrs: attr_key, other_type: attributes.class
        }
      end

      attributes.each do |key, attr|
        raise Puppet::DevError, "`#{definition[:name]}.#{key}` must be a Hash, not a #{attr.class}" unless attr.is_a? Hash
        raise Puppet::DevError, "`#{definition[:name]}.#{key}` has no type" unless attr.key? :type
        Puppet.warning("`#{definition[:name]}.#{key}` has no docs") unless attr.key? :desc

        # validate the type by attempting to parse into a puppet type
        @data_type_cache[attributes[key][:type]] ||=
          Puppet::ResourceApi::DataTypeHandling.parse_puppet_type(
            key,
            attributes[key][:type],
          )

        # fixup any weird behavior  ;-)
        next unless attr[:behavior]
        if attr[:behaviour]
          raise Puppet::DevError, "the '#{key}' attribute has both a `behavior` and a `behaviour`, only use one"
        end
        attr[:behaviour] = attr[:behavior]
        attr.delete(:behavior)
      end
      # store the validated definition
      @definition = definition
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
        type = @data_type_cache[attributes[key][:type]]
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
end
