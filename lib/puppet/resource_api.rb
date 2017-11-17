require 'pathname'
require 'puppet/resource_api/command'
require 'puppet/resource_api/errors'
require 'puppet/resource_api/glue'
require 'puppet/resource_api/puppet_context'
require 'puppet/resource_api/version'
require 'puppet/type'

module Puppet::ResourceApi
  def register_type(definition)
    raise Puppet::DevError, 'requires a Hash as definition, not %{other_type}' % { other_type: definition.class } unless definition.is_a? Hash
    raise Puppet::DevError, 'requires a name' unless definition.key? :name
    raise Puppet::DevError, 'requires attributes' unless definition.key? :attributes

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

      if definition[:features] && definition[:features].include?('remote_resource')
        apply_to_device
      end

      define_method(:initialize) do |attributes|
        # $stderr.puts "A: #{attributes.inspect}"
        attributes = attributes.to_hash if attributes.is_a? Puppet::Resource
        # $stderr.puts "B: #{attributes.inspect}"
        if definition.key?(:features) && definition[:features].include?('canonicalize')
          attributes = my_provider.canonicalize(context, [attributes])[0]
        end
        # $stderr.puts "C: #{attributes.inspect}"
        super(attributes)
      end

      definition[:attributes].each do |name, options|
        # puts "#{name}: #{options.inspect}"

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
            # TODO: this should use Pops infrastructure to avoid hardcoding stuff, and enhance type fidelity
            # validate do |v|
            #   type = Puppet::Pops::Types::TypeParser.singleton.parse(options[:type]).normalize
            #   if type.instance?(v)
            #     return true
            #   else
            #     inferred_type = Puppet::Pops::Types::TypeCalculator.infer_set(value)
            #     error_msg = Puppet::Pops::Types::TypeMismatchDescriber.new.describe_mismatch("#{DEFINITION[:name]}.#{name}", type, inferred_type)
            #     raise Puppet::ResourceError, error_msg
            #   end
            # end

            if options.key? :default
              defaultto options[:default]
            end

            case options[:type]
            when 'String'
              # require any string value
              newvalues %r{} do
              end
            # rubocop:disable Lint/BooleanSymbol
            when 'Boolean'
              newvalues 'true', 'false', :true, :false, true, false

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
            when 'Integer'
              newvalue %r{^-?\d+$} do
              end
              munge do |v|
                Puppet::Pops::Utils.to_n(v)
              end
            when 'Float', 'Numeric'
              newvalue Puppet::Pops::Patterns::NUMERIC do
              end
              munge do |v|
                Puppet::Pops::Utils.to_n(v)
              end
            when 'Enum[present, absent]'
              newvalue :absent do
              end
              newvalue :present do
              end
            when 'Variant[Pattern[/\A(0x)?[0-9a-fA-F]{8}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{16}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{40}\Z/]]'
              # the namevar needs to be a Parameter, which only has newvalue*s*
              newvalues(%r{\A(0x)?[0-9a-fA-F]{8}\Z}, %r{\A(0x)?[0-9a-fA-F]{16}\Z}, %r{\A(0x)?[0-9a-fA-F]{40}\Z})
            when 'Optional[String]'
              newvalues(%r{}, :undef) do
              end
            when 'Variant[Stdlib::Absolutepath, Pattern[/\A(https?|ftp):\/\//]]'
              # TODO: this is wrong, but matches original implementation
              [/^\//, /\A(https?|ftp):\/\//].each do |v| # rubocop:disable Style/RegexpLiteral
                newvalues v do
                end
              end
            when 'Pattern[/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/]'
              newvalues(/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/) # rubocop:disable Style/RegexpLiteral
            else
              raise Puppet::DevError, "Datatype #{options[:type]} is not yet supported in this prototype"
            end
          end
        end
      end

      define_singleton_method(:instances) do
        # puts 'instances'
        # force autoloading of the provider
        provider(name)
        my_provider.get(context).map do |resource_hash|
          Puppet::ResourceApi::TypeShim.new(resource_hash[namevar_name], resource_hash)
        end
      end

      define_method(:retrieve) do
        # puts "retrieve(#{title.inspect})"
        result        = Puppet::Resource.new(self.class, title)
        current_state = my_provider.get(context).find { |h| h[namevar_name] == title }

        # require 'pry'; binding.pry

        if current_state
          current_state.each do |k, v|
            result[k] = v
          end
        else
          result[:name] = title
          result[:ensure] = :absent
        end

        # puts "retrieved #{current_state.inspect}"

        @rapi_current_state = current_state
        result
      end

      define_method(:flush) do
        # puts 'flush'
        # require'pry';binding.pry
        target_state = Hash[@parameters.map { |k, v| [k, v.value] }]
        # remove puppet's injected metaparams
        target_state.delete(:loglevel)
        target_state = my_provider.canonicalize(context, [target_state]).first if definition.key?(:features) && definition[:features].include?('canonicalize')

        retrieve unless @rapi_current_state

        # require 'pry'; binding.pry
        return if @rapi_current_state == target_state

        puts "@rapi_current_state: #{@rapi_current_state.inspect}"
        puts "target_state: #{target_state.inspect}"

        my_provider.set(context, title => { is: @rapi_current_state, should: target_state })
        raise 'Execution encountered an error' if context.failed?
      end

      define_singleton_method(:context) do
        @context ||= PuppetContext.new(definition[:name])
      end

      def context
        self.class.context
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
end
