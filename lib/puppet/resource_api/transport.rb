module Puppet::ResourceApi; end # rubocop:disable Style/Documentation

# Remote target transport API
module Puppet::ResourceApi::Transport
  def register(schema)
    raise Puppet::DevError, 'requires a hash as schema, not `%{other_type}`' % { other_type: schema.class } unless schema.is_a? Hash
    raise Puppet::DevError, 'requires a `:name`' unless schema.key? :name
    raise Puppet::DevError, 'requires `:desc`' unless schema.key? :desc
    raise Puppet::DevError, 'requires `:connection_info`' unless schema.key? :connection_info
    raise Puppet::DevError, '`:connection_info` must be a hash, not `%{other_type}`' % { other_type: schema[:connection_info].class } unless schema[:connection_info].is_a?(Hash)

    unless transports[schema[:name]].nil?
      raise Puppet::DevError, 'Transport `%{name}` is already registered for `%{environment}`' % {
        name: schema[:name],
        environment: current_environment,
      }
    end
    transports[schema[:name]] = Puppet::ResourceApi::TransportSchemaDef.new(schema)
  end
  module_function :register # rubocop:disable Style/AccessModifierDeclarations

  # retrieve a Hash of transport schemas, keyed by their name.
  # Only already loaded transports are returned.
  def list
    Marshal.load(Marshal.dump(transports))
  end
  module_function :list # rubocop:disable Style/AccessModifierDeclarations

  # retrieve a Hash of transport schemas, keyed by their name.
  # This uses the Puppet autoloader, provide a  environment name as `force_environment`
  # to choose where to load from.
  # @api private
  def list_all_transports(force_environment)
    env = Puppet.lookup(:environments).get!(force_environment)
    Puppet.override({ current_environment: env }, 'current env for list_all_transports') do
      load_all_schemas
      Marshal.load(Marshal.dump(transports))
    end
  end
  module_function :list_all_transports # rubocop:disable Style/AccessModifierDeclarations

  # Loads all schemas using the Puppet Autoloader.
  def self.load_all_schemas
    require 'puppet'
    require 'puppet/settings'
    require 'puppet/util/autoload'
    @autoloader ||= Puppet::Util::Autoload.new(self, 'puppet/transport/schema')
    @autoloader.loadall(Puppet.lookup(:current_environment))
  end
  private_class_method :load_all_schemas

  def connect(name, connection_info)
    validate(name, connection_info)
    require "puppet/transport/#{name}"
    class_name = name.split('_').map { |e| e.capitalize }.join
    Puppet::Transport.const_get(class_name).new(get_context(name), wrap_sensitive(name, connection_info))
  end
  module_function :connect # rubocop:disable Style/AccessModifierDeclarations

  def inject_device(name, transport)
    transport_wrapper = Puppet::ResourceApi::Transport::Wrapper.new(name, transport)

    if Puppet::Util::NetworkDevice.respond_to?(:set_device)
      Puppet::Util::NetworkDevice.set_device(name, transport_wrapper)
    else
      Puppet::Util::NetworkDevice.instance_variable_set(:@current, transport_wrapper)
    end
  end
  module_function :inject_device # rubocop:disable Style/AccessModifierDeclarations

  def self.validate(name, connection_info)
    require "puppet/transport/schema/#{name}" unless transports.key? name
    transport_schema = transports[name]
    if transport_schema.nil?
      raise Puppet::DevError, 'Transport for `%{target}` not registered with `%{environment}`' % {
        target: name,
        environment: current_environment,
      }
    end

    if connection_info.key?(:"remote-transport")
      clean_bolt_attributes(transport_schema, connection_info)
    end

    message_prefix = 'The connection info provided does not match the Transport Schema'
    transport_schema.check_schema(connection_info, message_prefix)
    transport_schema.validate(connection_info)
  end
  private_class_method :validate

  def self.get_context(name)
    require 'puppet/resource_api/puppet_context'
    Puppet::ResourceApi::PuppetContext.new(transports[name])
  end
  private_class_method :get_context

  def self.wrap_sensitive(name, connection_info)
    transport_schema = transports[name]
    if transport_schema
      transport_schema.definition[:connection_info].each do |attr_name, options|
        if options.key?(:sensitive) && (options[:sensitive] == true) && connection_info.key?(attr_name)
          connection_info[attr_name] = Puppet::Pops::Types::PSensitiveType::Sensitive.new(connection_info[attr_name])
        end
      end
    end
    connection_info
  end
  private_class_method :wrap_sensitive

  def self.transports
    @transports ||= {}
    @transports[current_environment] ||= {}
  end
  private_class_method :transports

  def self.current_environment
    if Puppet.respond_to? :lookup
      env = Puppet.lookup(:current_environment)
      env.nil? ? :transports_default : env.name
    else
      :transports_default
    end
  end
  private_class_method :current_environment

  def self.clean_bolt_attributes(transport_schema, connection_info)
    context = get_context(transport_schema.name)

    # Attributes we expect from bolt, but want to ignore if the transport does not expect them
    [:uri, :host, :protocol, :user, :port, :password].each do |attribute_name|
      if connection_info.key?(attribute_name) && !transport_schema.attributes.key?(attribute_name)
        context.info('Discarding superfluous bolt attribute: %{attribute_name}' % { attribute_name: attribute_name })
        connection_info.delete(attribute_name)
      end
    end

    # Attributes that bolt emits, but we want to ignore if the transport does not expect them
    ([:name, :path, :query, :"run-on", :"remote-transport", :implementations] + connection_info.keys.select { |k| k.to_s.start_with? 'remote-' }).each do |attribute_name|
      if connection_info.key?(attribute_name) && !transport_schema.attributes.key?(attribute_name)
        context.debug('Discarding bolt metaparameter: %{attribute_name}' % { attribute_name: attribute_name })
        connection_info.delete(attribute_name)
      end
    end

    # remove any other attributes the transport is not prepared to handle
    connection_info.keys.each do |attribute_name|
      if connection_info.key?(attribute_name) && !transport_schema.attributes.key?(attribute_name)
        context.warning('Discarding unknown attribute: %{attribute_name}' % { attribute_name: attribute_name })
        connection_info.delete(attribute_name)
      end
    end

    # don't return a value as we've already modified the hash
    nil
  end
  private_class_method :clean_bolt_attributes
end
