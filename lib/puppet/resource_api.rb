require 'pathname'
require 'puppet/resource_api/glue'
require 'puppet/resource_api/puppet_context' unless RUBY_PLATFORM == 'java'
require 'puppet/resource_api/version'
require 'puppet/type'

module Puppet::ResourceApi
  def register_type(definition)
    raise Puppet::DevError, 'requires a Hash as definition, not %{other_type}' % { other_type: definition.class } unless definition.is_a? Hash
    raise Puppet::DevError, 'requires a name' unless definition.key? :name
    raise Puppet::DevError, 'requires attributes' unless definition.key? :attributes

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
    unless Puppet::Provider.const_defined?(class_name_from_type_name(definition[:name]))
      Puppet::Provider.const_set(class_name_from_type_name(definition[:name]), Module.new)
    end

    Puppet::Type.newtype(definition[:name].to_sym) do
      @docs = definition[:docs]
      has_namevar = false
      namevar_name = nil

      # Keeps a copy of the provider around. Weird naming to avoid clashes with puppet's own `provider` member
      define_singleton_method(:my_provider) do
        @my_provider ||= Puppet::ResourceApi.load_provider(definition[:name]).new
      end

      # make the provider available in the instance's namespace
      def my_provider
        self.class.my_provider
      end

      define_singleton_method(:feature_support?) do |feature|
        definition[:features] && definition[:features].include?(feature)
      end

      def feature_support?(feature)
        self.class.feature_support?(feature)
      end

      if feature_support?('remote_resource')
        apply_to_device
      end

      define_method(:initialize) do |attributes|
        # $stderr.puts "A: #{attributes.inspect}"
        if attributes.is_a? Puppet::Resource
          attributes = attributes.to_hash
        else
          @called_from_resource = true
        end
        # $stderr.puts "B: #{attributes.inspect}"
        if feature_support?('canonicalize')
          attributes = my_provider.canonicalize(context, [attributes])[0]
        end
        # $stderr.puts "C: #{attributes.inspect}"
        super(attributes)
      end

      validate do
        # enforce mandatory attributes
        missing_attrs = []
        definition[:attributes].each do |name, options|
          type = Puppet::Pops::Types::TypeParser.singleton.parse(options[:type])
          # skip read only vars and the namevar
          next if [:read_only, :namevar].include? options[:behaviour]

          # skip properties if the resource is being deleted
          next if definition[:attributes][:ensure] &&
                  value(:ensure) == :absent &&
                  options[:behaviour].nil?

          if value(name).nil? && !(type.instance_of? Puppet::Pops::Types::POptionalType)
            missing_attrs << name
          end
        end

        missing_attrs -= [:ensure] if @called_from_resource

        if missing_attrs.any?
          error_msg = "The following mandatory attributes where not provided:\n    *  " + missing_attrs.join(", \n    *  ")
          raise Puppet::ResourceError, error_msg
        end
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
            # puts 'setting namevar'
            # raise Puppet::DevError, "namevar must be called 'name', not '#{name}'" if name.to_s != 'name'
            isnamevar
            has_namevar = true
            namevar_name = name
          end

          # read-only values do not need type checking, but can have default values
          if options[:behaviour] != :read_only
            if options.key? :default
              defaultto options[:default]
            end
          end

          type = Puppet::Pops::Types::TypeParser.singleton.parse(options[:type])
          validate do |value|
            if options[:behaviour] == :read_only
              raise Puppet::ResourceError, "Attempting to set `#{name}` read_only attribute value to `#{value}`"
            end

            return true if type.instance?(value)

            if value.is_a? String
              # when running under `puppet resource`, we need to try to coerce from strings to the real type
              case value
              when %r{^-?\d+$}, Puppet::Pops::Patterns::NUMERIC
                value = Puppet::Pops::Utils.to_n(value)
              when %r{\Atrue|false\Z}
                value = value == 'true'
              end
              return true if type.instance?(value)

              inferred_type = Puppet::Pops::Types::TypeCalculator.infer_set(value)
              error_msg = Puppet::Pops::Types::TypeMismatchDescriber.new.describe_mismatch("#{definition[:name]}.#{name}", type, inferred_type)
              raise Puppet::ResourceError, error_msg
            end
          end

          if type.instance_of? Puppet::Pops::Types::POptionalType
            type = type.type
          end

          # provide better handling of the standard types
          case type
          when Puppet::Pops::Types::PStringType
            # require any string value
            Puppet::ResourceApi.def_newvalues(self, param_or_property, %r{})
          # rubocop:disable Lint/BooleanSymbol
          when Puppet::Pops::Types::PBooleanType
            Puppet::ResourceApi.def_newvalues(self, param_or_property, 'true', 'false')
            aliasvalue true, 'true'
            aliasvalue false, 'false'
            aliasvalue :true, 'true'
            aliasvalue :false, 'false'

            munge do |v|
              case v
              when 'true', :true
                true
              when 'false', :false
                false
              else
                v
              end
            end
          # rubocop:enable Lint/BooleanSymbol
          when Puppet::Pops::Types::PIntegerType
            Puppet::ResourceApi.def_newvalues(self, param_or_property, %r{^-?\d+$})
            munge do |v|
              Puppet::Pops::Utils.to_n(v)
            end
          when Puppet::Pops::Types::PFloatType, Puppet::Pops::Types::PNumericType
            Puppet::ResourceApi.def_newvalues(self, param_or_property, Puppet::Pops::Patterns::NUMERIC)
            munge do |v|
              Puppet::Pops::Utils.to_n(v)
            end
          end

          case options[:type]
          when 'Enum[present, absent]'
            Puppet::ResourceApi.def_newvalues(self, param_or_property, :absent, :present)
          end
        end
      end

      define_singleton_method(:instances) do
        # puts 'instances'
        # force autoloading of the provider
        provider(name)
        attr_def = {}
        my_provider.get(context).map do |resource_hash|
          resource_hash.each do |key|
            property = definition[:attributes][key.first]
            attr_def[key.first] = property
          end
          if resource_hash[namevar_name].nil?
            raise Puppet::ResourceError, "`#{name}.get` did not return a value for the `#{namevar_name}` namevar attribute"
          end
          Puppet::ResourceApi::TypeShim.new(resource_hash[namevar_name], resource_hash, name, namevar_name, attr_def)
        end
      end

      define_method(:retrieve) do
        # puts "retrieve(#{title.inspect})"
        result = Puppet::Resource.new(self.class, title)

        current_state = if feature_support?('simple_get_filter')
                          my_provider.get(context, [title]).first
                        else
                          my_provider.get(context).find { |h| h[namevar_name] == title }
                        end

        strict_check(current_state) if current_state && feature_support?('canonicalize')

        # require 'pry'; binding.pry

        if current_state
          current_state.each do |k, v|
            result[k] = v
          end
        else
          result[namevar_name] = title
          result[:ensure] = :absent
        end

        @rapi_current_state = current_state
        Puppet.debug("Current State: #{@rapi_current_state.inspect}")
        result
      end

      define_method(:flush) do
        # puts 'flush'
        target_state = Hash[@parameters.map { |k, v| [k, v.value] }]
        # remove puppet's injected metaparams
        target_state.delete(:loglevel)
        target_state = my_provider.canonicalize(context, [target_state]).first if feature_support?('canonicalize')

        retrieve unless @rapi_current_state

        # require 'pry'; binding.pry
        return if @rapi_current_state == target_state

        Puppet.debug("Target State: #{target_state.inspect}")

        # enforce init_only attributes
        if Puppet.settings[:strict] != :off && @rapi_current_state && (@rapi_current_state[:ensure] == :present && target_state[:ensure] == :present)
          target_state.each do |name, value|
            next unless definition[:attributes][name][:behaviour] == :init_only && value != @rapi_current_state[name]
            message = "Attempting to change `#{name}` init_only attribute value from `#{@rapi_current_state[name]}` to `#{value}`"
            case Puppet.settings[:strict]
            when :warning
              Puppet.warning(message)
            when :error
              raise Puppet::ResourceError, message
            end
          end
        end

        if feature_support?('supports_noop')
          my_provider.set(context, { title => { is: @rapi_current_state, should: target_state } }, noop: noop?)
        else
          my_provider.set(context, title => { is: @rapi_current_state, should: target_state }) unless noop?
        end
        raise 'Execution encountered an error' if context.failed?
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
#{definition[:name]}[#{current_state[namevar_name]}]#get has not provided canonicalized values.
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
        @context ||= PuppetContext.new(definition[:name])
      end

      def context
        self.class.context
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
  module_function :register_type

  def load_provider(type_name)
    class_name = class_name_from_type_name(type_name)
    type_name_sym = type_name.to_sym

    # loads the "puppet/provider/#{type_name}/#{type_name}" file through puppet
    Puppet::Type.type(type_name_sym).provider(type_name_sym)
    Puppet::Provider.const_get(class_name).const_get(class_name)
  rescue NameError
    raise Puppet::DevError, "class #{class_name} not found in puppet/provider/#{type_name}/#{type_name}"
  end
  module_function :load_provider

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
end
