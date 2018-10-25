require 'pathname'
require 'puppet/resource_api/glue'
require 'puppet/resource_api/puppet_context' unless RUBY_PLATFORM == 'java'
require 'puppet/resource_api/type_definition'
require 'puppet/resource_api/version'
require 'puppet/type'
require 'puppet/util/network_device'

module Puppet::ResourceApi
  @warning_count = 0

  class << self
    attr_accessor :warning_count
  end

  def register_type(definition)
    raise Puppet::DevError, 'requires a hash as definition, not `%{other_type}`' % { other_type: definition.class } unless definition.is_a? Hash
    raise Puppet::DevError, 'requires a `:name`' unless definition.key? :name
    raise Puppet::DevError, 'requires `:attributes`' unless definition.key? :attributes
    raise Puppet::DevError, '`:attributes` must be a hash, not `%{other_type}`' % { other_type: definition[:attributes].class } unless definition[:attributes].is_a?(Hash)
    [:title, :provider, :alias, :audit, :before, :consume, :export, :loglevel, :noop, :notify, :require, :schedule, :stage, :subscribe, :tag].each do |name|
      raise Puppet::DevError, 'must not define an attribute called `%{name}`' % { name: name.inspect } if definition[:attributes].key? name
    end
    if definition.key?(:title_patterns) && !definition[:title_patterns].is_a?(Array)
      raise Puppet::DevError, '`:title_patterns` must be an array, not `%{other_type}`' % { other_type: definition[:title_patterns].class }
    end

    validate_ensure(definition)

    definition[:features] ||= []
    supported_features = %w[supports_noop canonicalize remote_resource simple_get_filter].freeze
    unknown_features = definition[:features] - supported_features
    Puppet.warning("Unknown feature detected: #{unknown_features.inspect}") unless unknown_features.empty?

    # fixup any weird behavior  ;-)
    definition[:attributes].each do |name, attr|
      next unless attr[:behavior]
      if attr[:behaviour]
        raise Puppet::DevError, "the '#{name}' attribute has both a `behavior` and a `behaviour`, only use one"
      end
      attr[:behaviour] = attr[:behavior]
      attr.delete(:behavior)
    end

    # prepare the ruby module for the provider
    # this has to happen before Puppet::Type.newtype starts autoloading providers
    # it also needs to be guarded against the namespace already being defined by something
    # else to avoid ruby warnings
    unless Puppet::Provider.const_defined?(class_name_from_type_name(definition[:name]), false)
      Puppet::Provider.const_set(class_name_from_type_name(definition[:name]), Module.new)
    end

    Puppet::Type.newtype(definition[:name].to_sym) do
      @docs = definition[:docs]

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
        @type_definition ||= TypeDefinition.new(definition)
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
          type = Puppet::ResourceApi.parse_puppet_type(:name, options[:type])

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
        param_or_property = if [:read_only, :parameter, :namevar].include? options[:behaviour]
                              :newparam
                            else
                              :newproperty
                            end

        send(param_or_property, name.to_sym) do
          unless options[:type]
            raise Puppet::DevError, "#{definition[:name]}.#{name} has no type"
          end

          if options[:desc]
            desc "#{options[:desc]} (a #{options[:type]})"
          else
            warn("#{definition[:name]}.#{name} has no docs")
          end

          if options[:behaviour] == :namevar
            isnamevar
          end

          # read-only values do not need type checking, but can have default values
          if options[:behaviour] != :read_only && options.key?(:default)
            if options.key? :default
              if options[:default] == false
                # work around https://tickets.puppetlabs.com/browse/PUP-2368
                defaultto :false # rubocop:disable Lint/BooleanSymbol
              elsif options[:default] == true
                # work around https://tickets.puppetlabs.com/browse/PUP-2368
                defaultto :true # rubocop:disable Lint/BooleanSymbol
              else
                # marshal the default option to decouple that from the actual value.
                # we cache the dumped value in `marshalled`, but use a block to unmarshal
                # everytime the value is requested. Objects that can't be marshalled
                # See https://stackoverflow.com/a/8206537/4918
                marshalled = Marshal.dump(options[:default])
                defaultto { Marshal.load(marshalled) } # rubocop:disable Security/MarshalLoad
              end
            end
          end

          if name == :ensure
            def insync?(is)
              rs_value.to_s == is.to_s
            end
          end

          type = Puppet::ResourceApi.parse_puppet_type(name, options[:type])

          if param_or_property == :newproperty
            define_method(:should) do
              if name == :ensure && rs_value.is_a?(String)
                rs_value.to_sym
              elsif rs_value == false
                # work around https://tickets.puppetlabs.com/browse/PUP-2368
                :false # rubocop:disable Lint/BooleanSymbol
              elsif rs_value == true
                # work around https://tickets.puppetlabs.com/browse/PUP-2368
                :true # rubocop:disable Lint/BooleanSymbol
              else
                rs_value
              end
            end

            define_method(:should=) do |value|
              @shouldorig = value

              if name == :ensure
                value = value.to_s
              end

              # Puppet requires the @should value to always be stored as an array. We do not use this
              # for anything else
              # @see Puppet::Property.should=(value)
              @should = [Puppet::ResourceApi.mungify(type, value, "#{definition[:name]}.#{name}")]
            end

            # used internally
            # @returns the final mungified value of this property
            define_method(:rs_value) do
              @should ? @should.first : @should
            end
          else
            define_method(:value) do
              @value
            end

            define_method(:value=) do |value|
              if options[:behaviour] == :read_only
                raise Puppet::ResourceError, "Attempting to set `#{name}` read_only attribute value to `#{value}`"
              end

              @value = Puppet::ResourceApi.mungify(type, value, "#{definition[:name]}.#{name}")
            end

            # used internally
            # @returns the final mungified value of this parameter
            define_method(:rs_value) do
              @value
            end
          end

          # puppet symbolizes some values through puppet/parameter/value.rb (see .convert()), but (especially) Enums
          # are strings. specifying a munge block here skips the value_collection fallback in puppet/parameter.rb's
          # default .unsafe_munge() implementation.
          munge { |v| v }

          # provide hints to `puppet type generate` for better parsing
          if type.instance_of? Puppet::Pops::Types::POptionalType
            type = type.type
          end

          case type
          when Puppet::Pops::Types::PStringType
            # require any string value
            Puppet::ResourceApi.def_newvalues(self, param_or_property, %r{})
          when Puppet::Pops::Types::PBooleanType
            Puppet::ResourceApi.def_newvalues(self, param_or_property, 'true', 'false')
            aliasvalue true, 'true'
            aliasvalue false, 'false'
            aliasvalue :true, 'true' # rubocop:disable Lint/BooleanSymbol
            aliasvalue :false, 'false' # rubocop:disable Lint/BooleanSymbol

          when Puppet::Pops::Types::PIntegerType
            Puppet::ResourceApi.def_newvalues(self, param_or_property, %r{^-?\d+$})
          when Puppet::Pops::Types::PFloatType, Puppet::Pops::Types::PNumericType
            Puppet::ResourceApi.def_newvalues(self, param_or_property, Puppet::Pops::Patterns::NUMERIC)
          end

          if param_or_property == :newproperty
            # stop puppet from trying to call into the provider when
            # no pre-defined values have been specified
            # "This is not the provider you are looking for." -- Obi-Wan Kaniesobi.
            def call_provider(value); end
          end

          case options[:type]
          when 'Enum[present, absent]'
            Puppet::ResourceApi.def_newvalues(self, param_or_property, 'absent', 'present')
          end
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
    Puppet::Provider.const_get(class_name).const_get(class_name)
  end
  module_function :load_default_provider # rubocop:disable Style/AccessModifierDeclarations

  def load_device_provider(class_name, type_name_sym, device_class_name, device_name_sym)
    # loads the "puppet/provider/#{type_name}/#{device_name}" file through puppet
    Puppet::Type.type(type_name_sym).provider(device_name_sym)
    provider_module = Puppet::Provider.const_get(class_name)
    if provider_module.const_defined?(device_class_name)
      provider_module.const_get(device_class_name)
    else
      load_default_provider(class_name, type_name_sym)
    end
  end
  module_function :load_device_provider # rubocop:disable Style/AccessModifierDeclarations

  def self.class_name_from_type_name(type_name)
    type_name.to_s.split('_').map(&:capitalize).join
  end

  # Add the value to `this` property or param, depending on whether param_or_property is `:newparam`, or `:newproperty`
  def self.def_newvalues(this, param_or_property, *values)
    if param_or_property == :newparam
      this.newvalues(*values)
    else
      values.each do |v|
        this.newvalue(v) {}
      end
    end
  end

  def self.caller_is_resource_app?
    caller.any? { |c| c.match(%r{application/resource.rb:}) }
  end

  # This method handles translating values from the runtime environment to the expected types for the provider.
  # When being called from `puppet resource`, it tries to transform the strings from the command line into their
  # expected ruby representations, e.g. `"2"` (a string), will be transformed to `2` (the number) if (and only if)
  # the target `type` is `Integer`.
  # Additionally this function also validates that the passed in (and optionally transformed) value matches the
  # specified type.
  # @param type[Puppet::Pops::Types::TypedModelObject] the type to check/clean against
  # @param value the value to clean
  # @param error_msg_prefix[String] a prefix for the error messages
  # @return [type] the cleaned value
  # @raise [Puppet::ResourceError] if `value` could not be parsed into `type`
  def self.mungify(type, value, error_msg_prefix)
    if caller_is_resource_app?
      # When the provider is exercised from the `puppet resource` CLI, we need to unpack strings into
      # the correct types, e.g. "1" (a string) to 1 (an integer)
      cleaned_value, error_msg = try_mungify(type, value, error_msg_prefix)
      raise Puppet::ResourceError, error_msg if error_msg
    elsif value == :false # rubocop:disable Lint/BooleanSymbol
      # work around https://tickets.puppetlabs.com/browse/PUP-2368
      cleaned_value = false
    elsif value == :true # rubocop:disable Lint/BooleanSymbol
      # work around https://tickets.puppetlabs.com/browse/PUP-2368
      cleaned_value = true
    else
      # Every other time, we can use the values as is
      cleaned_value = value
    end
    Puppet::ResourceApi.validate(type, cleaned_value, error_msg_prefix)
    cleaned_value
  end

  # Recursive implementation part of #mungify. Uses a multi-valued return value to avoid excessive
  #   exception throwing for regular usage
  # @return [Array] if the mungify worked, the first element is the cleaned value, and the second
  #   element is nil. If the mungify failed, the first element is nil, and the second element is an error
  #   message
  # @private
  def self.try_mungify(type, value, error_msg_prefix)
    case type
    when Puppet::Pops::Types::PArrayType
      if value.is_a? Array
        conversions = value.map do |v|
          try_mungify(type.element_type, v, error_msg_prefix)
        end
        # only convert the values if none failed. otherwise fall through and rely on puppet to render a proper error
        if conversions.all? { |c| c[1].nil? }
          value = conversions.map { |c| c[0] }
        end
      end
    when Puppet::Pops::Types::PBooleanType
      value = case value
              when 'true', :true # rubocop:disable Lint/BooleanSymbol
                true
              when 'false', :false # rubocop:disable Lint/BooleanSymbol
                false
              else
                value
              end
    when Puppet::Pops::Types::PIntegerType, Puppet::Pops::Types::PFloatType, Puppet::Pops::Types::PNumericType
      if value =~ %r{^-?\d+$} || value =~ Puppet::Pops::Patterns::NUMERIC
        value = Puppet::Pops::Utils.to_n(value)
      end
    when Puppet::Pops::Types::PEnumType, Puppet::Pops::Types::PStringType, Puppet::Pops::Types::PPatternType
      if value.is_a? Symbol
        value = value.to_s
      end
    when Puppet::Pops::Types::POptionalType
      return value.nil? ? [nil, nil] : try_mungify(type.type, value, error_msg_prefix)
    when Puppet::Pops::Types::PVariantType
      # try converting to anything except string first
      string_type = type.types.find { |t| t.is_a? Puppet::Pops::Types::PStringType }
      conversion_results = (type.types - [string_type]).map do |t|
        try_mungify(t, value, error_msg_prefix)
      end

      # only consider valid results
      conversion_results = conversion_results.select { |r| r[1].nil? }.to_a

      # use the conversion result if unambiguous
      return conversion_results[0] if conversion_results.length == 1

      # return an error if ambiguous
      return [nil, "#{error_msg_prefix} #{value.inspect} is not unabiguously convertable to #{type}"] if conversion_results.length > 1

      # try to interpret as string
      return try_mungify(string_type, value, error_msg_prefix) if string_type

      # fall through to default handling
    end

    error_msg = try_validate(type, value, error_msg_prefix)
    if error_msg
      # an error :-(
      [nil, error_msg]
    else
      # a match!
      [value, nil]
    end
  end

  # Validates the `value` against the specified `type`.
  # @param type[Puppet::Pops::Types::TypedModelObject] the type to check against
  # @param value the value to clean
  # @param error_msg_prefix[String] a prefix for the error messages
  # @raise [Puppet::ResourceError] if `value` is not of type `type`
  # @private
  def self.validate(type, value, error_msg_prefix)
    error_msg = try_validate(type, value, error_msg_prefix)

    raise Puppet::ResourceError, error_msg if error_msg
  end

  # Tries to validate the `value` against the specified `type`.
  # @param type[Puppet::Pops::Types::TypedModelObject] the type to check against
  # @param value the value to clean
  # @param error_msg_prefix[String] a prefix for the error messages
  # @return [String, nil] a error message indicating the problem, or `nil` if the value was valid.
  # @private
  def self.try_validate(type, value, error_msg_prefix)
    return nil if type.instance?(value)

    # an error :-(
    inferred_type = Puppet::Pops::Types::TypeCalculator.infer_set(value)
    error_msg = Puppet::Pops::Types::TypeMismatchDescriber.new.describe_mismatch(error_msg_prefix, type, inferred_type)
    error_msg
  end

  def self.validate_ensure(definition)
    return unless definition[:attributes].key? :ensure
    options = definition[:attributes][:ensure]
    type = Puppet::ResourceApi.parse_puppet_type(:ensure, options[:type])

    return if type.is_a?(Puppet::Pops::Types::PEnumType) && type.values.sort == %w[absent present].sort
    raise Puppet::DevError, '`:ensure` attribute must have a type of: `Enum[present, absent]`'
  end

  def self.parse_puppet_type(attr_name, type)
    Puppet::Pops::Types::TypeParser.singleton.parse(type)
  rescue Puppet::ParseErrorWithIssue => e
    raise Puppet::DevError, "The type of the `#{attr_name}` attribute `#{type}` could not be parsed: #{e.message}"
  rescue Puppet::ParseError => e
    raise Puppet::DevError, "The type of the `#{attr_name}` attribute `#{type}` is not recognised: #{e.message}"
  end
end
