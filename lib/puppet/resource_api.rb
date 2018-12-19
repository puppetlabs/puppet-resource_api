require 'pathname'
require 'puppet/resource_api/data_type_handling'
require 'puppet/resource_api/glue'
require 'puppet/resource_api/parameter'
require 'puppet/resource_api/property'
require 'puppet/resource_api/puppet_context' unless RUBY_PLATFORM == 'java'
require 'puppet/resource_api/read_only_parameter'
require 'puppet/resource_api/transport'
require 'puppet/resource_api/type_definition'
require 'puppet/resource_api/value_creator'
require 'puppet/resource_api/version'
require 'puppet/type'
require 'puppet/util/network_device'

module Puppet::ResourceApi
  @warning_count = 0

  class << self
    attr_accessor :warning_count
  end

  def register_type(definition)
    # Attempt to create a TypeDefinition from the input hash
    # This will validate and throw if its not right
    type_def = TypeDefinition.new(definition)

    # prepare the ruby module for the provider
    # this has to happen before Puppet::Type.newtype starts autoloading providers
    # it also needs to be guarded against the namespace already being defined by something
    # else to avoid ruby warnings
    unless Puppet::Provider.const_defined?(class_name_from_type_name(definition[:name]), false)
      Puppet::Provider.const_set(class_name_from_type_name(definition[:name]), Module.new)
    end

    Puppet::Type.newtype(definition[:name].to_sym) do
      @docs = definition[:docs]
      @type_definition = type_def

      # Keeps a copy of the provider around. Weird naming to avoid clashes with puppet's own `provider` member
      define_singleton_method(:my_provider) do
        @my_provider ||= Hash.new { |hash, key| hash[key] = Puppet::ResourceApi.load_provider(definition[:name]).new }
        @my_provider[Puppet::Util::NetworkDevice.current.class]
      end

      # make the provider available in the instance's namespace
      def my_provider
        self.class.my_provider
      end

      define_singleton_method(:type_definition) do
        @type_definition
      end

      def type_definition
        self.class.type_definition
      end

      if type_definition.feature?('remote_resource')
        apply_to_device
      end

      define_method(:initialize) do |attributes|
        # $stderr.puts "A: #{attributes.inspect}"
        if attributes.is_a? Puppet::Resource
          @title = attributes.title
          @catalog = attributes.catalog
          sensitives = attributes.sensitive_parameters
          attributes = attributes.to_hash
        else
          @ral_find_absent = true
          sensitives = []
        end

        # undo puppet's unwrapping of Sensitive values to provide a uniform experience for providers
        # See https://tickets.puppetlabs.com/browse/PDK-1091 for investigation and background
        sensitives.each do |name|
          if attributes.key?(name) && !attributes[name].is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive)
            attributes[name] = Puppet::Pops::Types::PSensitiveType::Sensitive.new(attributes[name])
          end
        end

        # $stderr.puts "B: #{attributes.inspect}"
        if type_definition.feature?('canonicalize')
          attributes = my_provider.canonicalize(context, [attributes])[0]
        end

        # the `Puppet::Resource::Ral.find` method, when `instances` does not return a match, uses a Hash with a `:name` key to create
        # an "absent" resource. This is often hit by `puppet resource`. This needs to work, even if the namevar is not called `name`.
        # This bit here relies on the default `title_patterns` (see below) to match the title back to the first (and often only) namevar
        if definition[:attributes][:name].nil? && attributes[:title].nil?
          attributes[:title] = attributes.delete(:name)
          if attributes[:title].nil? && !type_definition.namevars.empty?
            attributes[:title] = @title
          end
        end

        super(attributes)
      end

      def name
        title
      end

      def to_resource
        to_resource_shim(super)
      end

      define_method(:to_resource_shim) do |resource|
        resource_hash = Hash[resource.keys.map { |k| [k, resource[k]] }]
        resource_hash[:title] = resource.title
        ResourceShim.new(resource_hash, type_definition.name, type_definition.namevars, type_definition.attributes, catalog)
      end

      validate do
        # enforce mandatory attributes
        @missing_attrs = []
        @missing_params = []

        # do not validate on known-absent instances
        return if @ral_find_absent

        definition[:attributes].each do |name, options|
          type = Puppet::ResourceApi::DataTypeHandling.parse_puppet_type(
            :name,
            options[:type],
          )

          # skip read only vars and the namevar
          next if [:read_only, :namevar].include? options[:behaviour]

          # skip properties if the resource is being deleted
          next if definition[:attributes][:ensure] &&
                  value(:ensure) == 'absent' &&
                  options[:behaviour].nil?

          if value(name).nil? && !(type.instance_of? Puppet::Pops::Types::POptionalType)
            @missing_attrs << name
            @missing_params << name if options[:behaviour] == :parameter
          end
        end

        @missing_attrs -= [:ensure]

        raise_missing_params if @missing_params.any?
      end

      definition[:attributes].each do |name, options|
        # puts "#{name}: #{options.inspect}"

        if options[:behaviour]
          unless [:read_only, :namevar, :parameter, :init_only].include? options[:behaviour]
            raise Puppet::ResourceError, "`#{options[:behaviour]}` is not a valid behaviour value"
          end
        end

        # TODO: using newparam everywhere would suppress change reporting
        #       that would allow more fine-grained reporting through context,
        #       but require more invest in hooking up the infrastructure to emulate existing data
        if [:parameter, :namevar].include? options[:behaviour]
          param_or_property = :newparam
          parent = Puppet::ResourceApi::Parameter
        elsif options[:behaviour] == :read_only
          param_or_property = :newparam
          parent = Puppet::ResourceApi::ReadOnlyParameter
        else
          param_or_property = :newproperty
          parent = Puppet::ResourceApi::Property
        end

        # This call creates a new parameter or property with all work-arounds or
        # customizations required by the Resource API applied. Under the hood,
        # this maps to the relevant DSL methods in Puppet::Type. See
        # https://puppet.com/docs/puppet/6.0/custom_types.html#reference-5883
        # for details.
        send(param_or_property, name.to_sym, parent: parent) do
          if options[:desc]
            desc "#{options[:desc]} (a #{options[:type]})"
          end

          # The initialize method is called when puppet core starts building up
          # type objects. The core passes in a hash of shape { resource:
          # #<Puppet::Type::TypeName> }. We use this to pass through the
          # required configuration data to the parent (see
          # Puppet::ResourceApi::Property, Puppet::ResourceApi::Parameter and
          # Puppet::ResourceApi::ReadOnlyParameter).
          define_method(:initialize) do |resource_hash|
            super(definition[:name], self.class.data_type, name, resource_hash)
          end

          # get pops data type object for this parameter or property
          define_singleton_method(:data_type) do
            @rsapi_data_type ||= Puppet::ResourceApi::DataTypeHandling.parse_puppet_type(
              name,
              options[:type],
            )
          end

          # from ValueCreator call create_values which makes alias values and
          # default values for properties and params
          Puppet::ResourceApi::ValueCreator.create_values(
            self,
            data_type,
            param_or_property,
            options,
          )
        end
      end

      define_singleton_method(:instances) do
        # puts 'instances'
        # force autoloading of the provider
        provider(type_definition.name)

        initial_fetch = if type_definition.feature?('simple_get_filter')
                          my_provider.get(context, [])
                        else
                          my_provider.get(context)
                        end

        initial_fetch.map do |resource_hash|
          type_definition.check_schema(resource_hash)
          # allow a :title from the provider to override the default
          result = if resource_hash.key? :title
                     new(title: resource_hash[:title])
                   else
                     new(title: resource_hash[type_definition.namevars.first])
                   end
          result.cache_current_state(resource_hash)
          result
        end
      end

      define_method(:refresh_current_state) do
        @rsapi_current_state = if type_definition.feature?('simple_get_filter')
                                 my_provider.get(context, [title]).find { |h| namevar_match?(h) }
                               else
                                 my_provider.get(context).find { |h| namevar_match?(h) }
                               end

        if @rsapi_current_state
          type_definition.check_schema(@rsapi_current_state)
          strict_check(@rsapi_current_state) if type_definition.feature?('canonicalize')
        else
          @rsapi_current_state = { title: title }
          @rsapi_current_state[:ensure] = :absent if type_definition.ensurable?
        end
      end

      # Use this to set the current state from the `instances` method
      def cache_current_state(resource_hash)
        @rsapi_current_state = resource_hash
        strict_check(@rsapi_current_state) if type_definition.feature?('canonicalize')
      end

      define_method(:retrieve) do
        refresh_current_state unless @rsapi_current_state

        Puppet.debug("Current State: #{@rsapi_current_state.inspect}")

        result = Puppet::Resource.new(self.class, title, parameters: @rsapi_current_state)
        # puppet needs ensure to be a symbol
        result[:ensure] = result[:ensure].to_sym if type_definition.ensurable? && result[:ensure].is_a?(String)

        raise_missing_attrs

        result
      end

      define_method(:namevar_match?) do |item|
        context.type.namevars.all? do |namevar|
          item[namevar] == @parameters[namevar].value if @parameters[namevar].respond_to? :value
        end
      end

      define_method(:flush) do
        raise_missing_attrs

        # puts 'flush'
        # skip puppet's injected metaparams
        actual_params = @parameters.select { |k, _v| type_definition.attributes.key? k }
        target_state = Hash[actual_params.map { |k, v| [k, v.rs_value] }]
        target_state = my_provider.canonicalize(context, [target_state]).first if type_definition.feature?('canonicalize')

        retrieve unless @rsapi_current_state

        return if @rsapi_current_state == target_state

        Puppet.debug("Target State: #{target_state.inspect}")

        # enforce init_only attributes
        if Puppet.settings[:strict] != :off && @rsapi_current_state && (@rsapi_current_state[:ensure] == 'present' && target_state[:ensure] == 'present')
          target_state.each do |name, value|
            next unless definition[:attributes][name][:behaviour] == :init_only && value != @rsapi_current_state[name]
            message = "Attempting to change `#{name}` init_only attribute value from `#{@rsapi_current_state[name]}` to `#{value}`"
            case Puppet.settings[:strict]
            when :warning
              Puppet.warning(message)
            when :error
              raise Puppet::ResourceError, message
            end
          end
        end

        if type_definition.feature?('supports_noop')
          my_provider.set(context, { title => { is: @rsapi_current_state, should: target_state } }, noop: noop?)
        else
          my_provider.set(context, title => { is: @rsapi_current_state, should: target_state }) unless noop?
        end
        raise 'Execution encountered an error' if context.failed?

        # remember that we have successfully reached our desired state
        @rsapi_current_state = target_state
      end

      define_method(:raise_missing_attrs) do
        error_msg = "The following mandatory attributes were not provided:\n    *  " + @missing_attrs.join(", \n    *  ")
        raise Puppet::ResourceError, error_msg if @missing_attrs.any? && (value(:ensure) != :absent && !value(:ensure).nil?)
      end

      define_method(:raise_missing_params) do
        error_msg = "The following mandatory parameters were not provided:\n    *  " + @missing_params.join(", \n    *  ")
        raise Puppet::ResourceError, error_msg
      end

      define_method(:strict_check) do |current_state|
        return if Puppet.settings[:strict] == :off

        # if strict checking is on we must notify if the values are changed by canonicalize
        # make a deep copy to perform the operation on and to compare against later
        state_clone = Marshal.load(Marshal.dump(current_state))
        state_clone = my_provider.canonicalize(context, [state_clone]).first

        # compare the clone against the current state to see if changes have been made by canonicalize
        return unless state_clone && (current_state != state_clone)

        #:nocov:
        # codecov fails to register this multiline as covered, even though simplecov does.
        message = <<MESSAGE.strip
#{definition[:name]}[#{@title}]#get has not provided canonicalized values.
Returned values:       #{current_state.inspect}
Canonicalized values:  #{state_clone.inspect}
MESSAGE
        #:nocov:

        case Puppet.settings[:strict]
        when :warning
          Puppet.warning(message)
        when :error
          raise Puppet::DevError, message
        end

        return nil
      end

      define_singleton_method(:context) do
        @context ||= PuppetContext.new(definition)
      end

      def context
        self.class.context
      end

      define_singleton_method(:title_patterns) do
        @title_patterns ||= if definition.key? :title_patterns
                              parse_title_patterns(definition[:title_patterns])
                            else
                              [[%r{(.*)}m, [[type_definition.namevars.first]]]]
                            end
      end

      # Creates a `title_pattern` compatible data structure to pass to the underlying puppet runtime environment.
      # It uses the named items in the regular expression to connect the dots
      #
      # @example `[ %r{^(?<package>.*[^-])-(?<manager>.*)$} ]` becomes
      #   [
      #     [
      #       %r{^(?<package>.*[^-])-(?<manager>.*)$},
      #       [ [:package], [:manager] ]
      #     ],
      #   ]
      def self.parse_title_patterns(patterns)
        patterns.map do |item|
          regex = Regexp.new(item[:pattern])
          [item[:pattern], regex.names.map { |x| [x.to_sym] }]
        end
      end

      [:autorequire, :autobefore, :autosubscribe, :autonotify].each do |auto|
        next unless definition[auto]

        definition[auto].each do |type, values|
          Puppet.debug("Registering #{auto} for #{type}: #{values.inspect}")
          send(auto, type.downcase.to_sym) do
            [values].flatten.map do |v|
              match = %r{\A\$(.*)\Z}.match(v) if v.is_a? String
              if match.nil?
                v
              else
                self[match[1].to_sym]
              end
            end
          end
        end
      end
    end
  end
  module_function :register_type # rubocop:disable Style/AccessModifierDeclarations

  def load_provider(type_name)
    class_name = class_name_from_type_name(type_name)
    type_name_sym = type_name.to_sym
    device_name = if Puppet::Util::NetworkDevice.current.nil?
                    nil
                  else
                    # extract the device type from the currently loaded device's class
                    Puppet::Util::NetworkDevice.current.class.name.split('::')[-2].downcase
                  end
    device_class_name = class_name_from_type_name(device_name)

    if device_name
      device_name_sym = device_name.to_sym if device_name
      load_device_provider(class_name, type_name_sym, device_class_name, device_name_sym)
    else
      load_default_provider(class_name, type_name_sym)
    end
  rescue NameError
    if device_name # line too long # rubocop:disable Style/GuardClause
      raise Puppet::DevError, "Found neither the device-specific provider class Puppet::Provider::#{class_name}::#{device_class_name} in puppet/provider/#{type_name}/#{device_name}"\
      " nor the generic provider class Puppet::Provider::#{class_name}::#{class_name} in puppet/provider/#{type_name}/#{type_name}"
    else
      raise Puppet::DevError, "provider class Puppet::Provider::#{class_name}::#{class_name} not found in puppet/provider/#{type_name}/#{type_name}"
    end
  end
  module_function :load_provider # rubocop:disable Style/AccessModifierDeclarations

  def load_default_provider(class_name, type_name_sym)
    # loads the "puppet/provider/#{type_name}/#{type_name}" file through puppet
    Puppet::Type.type(type_name_sym).provider(type_name_sym)
    Puppet::Provider.const_get(class_name, false).const_get(class_name, false)
  end
  module_function :load_default_provider # rubocop:disable Style/AccessModifierDeclarations

  def load_device_provider(class_name, type_name_sym, device_class_name, device_name_sym)
    # loads the "puppet/provider/#{type_name}/#{device_name}" file through puppet
    Puppet::Type.type(type_name_sym).provider(device_name_sym)
    provider_module = Puppet::Provider.const_get(class_name, false)
    if provider_module.const_defined?(device_class_name, false)
      provider_module.const_get(device_class_name, false)
    else
      load_default_provider(class_name, type_name_sym)
    end
  end
  module_function :load_device_provider # rubocop:disable Style/AccessModifierDeclarations

  # keeps the existing register API format. e.g. Puppet::ResourceApi.register_type
  def register_transport(schema)
    Puppet::ResourceApi::Transport.register(schema)
  end
  module_function :register_transport # rubocop:disable Style/AccessModifierDeclarations

  def self.class_name_from_type_name(type_name)
    type_name.to_s.split('_').map(&:capitalize).join
  end

  def self.caller_is_resource_app?
    caller.any? { |c| c.match(%r{application/resource.rb:}) }
  end
end
