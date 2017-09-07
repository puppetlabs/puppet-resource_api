require 'pathname'
require 'puppet/resource_api/version'
require 'puppet/type'

module Puppet::ResourceApi
  def register_type(definition)
    raise Puppet::DevError, 'requires a Hash as definition, not %{other_type}' % { other_type: definition.class } unless definition.is_a? Hash
    raise Puppet::DevError, 'requires a name' unless definition.key? :name
    raise Puppet::DevError, 'requires attributes' unless definition.key? :attributes

    # prepare the ruby module for the provider
    # this has to happen before Puppet::Type.newtype starts autoloading providers
    Puppet::Provider.const_set(class_name_from_type_name(definition[:name]), Module.new)

    Puppet::Type.newtype(definition[:name].to_sym) do
      @docs = definition[:docs]
      has_namevar = false
      namevar_name = nil

      define_method(:initialize) do |attributes|
        # $stderr.puts "A: #{attributes.inspect}"
        attributes = attributes.to_hash if attributes.is_a? Puppet::Resource
        # $stderr.puts "B: #{attributes.inspect}"
        if definition.key?(:features) && definition[:features].contains('canonicalize')
          attributes = self.class.canonicalize([attributes])[0]
        end
        # $stderr.puts "C: #{attributes.inspect}"
        super(attributes)
      end

      definition[:attributes].each do |name, options|
        # puts "#{name}: #{options.inspect}"

        # TODO: using newparam everywhere would suppress change reporting
        #       that would allow more fine-grained reporting through logger,
        #       but require more invest in hooking up the infrastructure to emulate existing data
        param_or_property = if options[:behaviour] == :read_only || options[:behaviour] == :namevar
                              :newparam
                            else
                              :newproperty
                            end
        send(param_or_property, name.to_sym) do
          unless options[:type]
            raise("#{definition[:name]}.#{name} has no type")
          end

          if options[:desc]
            desc "#{options[:desc]} (a #{options[:type]})"
          else
            warn("#{definition[:name]}.#{name} has no docs")
          end

          if options[:behaviour] == :namevar
            puts 'setting namevar'
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
              newvalue :undef do
              end
              newvalue %r{} do
              end
            when 'Variant[Stdlib::Absolutepath, Pattern[/\A(https?|ftp):\/\//]]'
              # TODO: this is wrong, but matches original implementation
              [/^\//, /\A(https?|ftp):\/\//].each do |v| # rubocop:disable Style/RegexpLiteral
                newvalue v do
                end
              end
            when 'Pattern[/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/]'
              newvalues(/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/) # rubocop:disable Style/RegexpLiteral
            when %r{^(Enum|Optional|Variant)}
              raise("Datatype #{Regexp.last_match(1)} is not yet supported in this prototype")
            else
              raise("Datatype #{options[:type]} is not yet supported in this prototype")
            end
          end
        end
      end

      define_singleton_method(:instances) do
        # puts 'instances'
        # force autoloading of the provider
        provider(name)
        get.map do |resource_hash|
          Puppet::SimpleResource::TypeShim.new(resource_hash[namevar_name], resource_hash)
        end
      end

      define_method(:retrieve) do
        # puts 'retrieve'
        result        = Puppet::Resource.new(self.class, title)
        current_state = self.class.get.find { |h| h[namevar_name] == title }

        if current_state
          current_state.each do |k, v|
            result[k] = v
          end
        else
          result[:ensure] = :absent
        end

        # puts 'retrieve done'

        @rapi_current_state = current_state
        result
      end

      def flush
        # puts 'flush'
        target_state = self.class.canonicalize([Hash[@parameters.map { |k, v| [k, v.value] }]]).first

        return if @rapi_current_state == target_state

        self.class.set({ title => @rapi_current_state }, { title => target_state }, false)
      end

      define_singleton_method(:logger) do
        PuppetLogger.new(definition[:name])
      end

      def self.commands(*args)
        args.each do |command_group|
          command_group.each do |command_name, command|
            # puts "registering command: #{command_name}, using #{command}"
            define_singleton_method(command_name) do |*command_args|
              # puts "spawn([#{command}, #{command}], #{command_args.inspect})"
              # TODO: capture output to debug stream
              p = Process.spawn([command, command], *command_args)
              Process.wait(p)
              unless $CHILD_STATUS.exitstatus.zero?
                raise Puppet::ResourceError, "#{command} failed with exit code #{$CHILD_STATUS.exitstatus}"
              end
            end

            define_singleton_method("#{command_name}_lines") do |*command_args|
              # puts "capture3([#{command}, #{command}], #{args.inspect})"
              stdin_str, _stderr_str, status = Open3.capture3([command, command], *command_args)
              unless status.exitstatus.zero?
                raise Puppet::ResourceError, "#{command} failed with exit code #{$CHILD_STATUS.exitstatus}"
              end
              stdin_str.split("\n")
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
end

module Puppet::SimpleResource
  class TypeShim
    attr_reader :values

    def initialize(title, resource_hash)
      # internalize and protect - needs to go deeper
      @values        = resource_hash.dup
      # "name" is a privileged key
      @values[:name] = title
      @values.freeze
    end

    def to_resource
      ResourceShim.new(@values)
    end

    def name
      values[:name]
    end
  end

  class ResourceShim
    attr_reader :values

    def initialize(resource_hash)
      @values = resource_hash.dup.freeze # whatevs
    end

    def title
      values[:name]
    end

    def prune_parameters(*_args)
      # puts "not pruning #{args.inspect}" if args.length > 0
      self
    end

    def to_manifest
      (["apt_key { #{values[:name].inspect}: "] + values.keys.reject { |k| k == :name }.map { |k| "  #{k} => #{values[k].inspect}," } + ['}']).join("\n")
    end
  end
end
