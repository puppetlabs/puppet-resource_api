module Puppet::ResourceApi; end # rubocop:disable Style/Documentation

# Remote target transport API
module Puppet::ResourceApi::Transport
  def register(schema)
    raise Puppet::DevError, 'requires a hash as schema, not `%{other_type}`' % { other_type: schema.class } unless schema.is_a? Hash
    raise Puppet::DevError, 'requires a `:name`' unless schema.key? :name
    raise Puppet::DevError, 'requires `:desc`' unless schema.key? :desc
    raise Puppet::DevError, 'requires `:connection_info`' unless schema.key? :connection_info
    raise Puppet::DevError, '`:connection_info` must be a hash, not `%{other_type}`' % { other_type: schema[:connection_info].class } unless schema[:connection_info].is_a?(Hash)

    init_transports
    unless @transports[@environment][schema[:name]].nil?
      raise Puppet::DevError, 'Transport `%{name}` is already registered for `%{environment}`' % {
        name: schema[:name],
        environment: @environment,
      }
    end
    @transports[@environment][schema[:name]] = Puppet::ResourceApi::TransportSchemaDef.new(schema)
  end
  module_function :register # rubocop:disable Style/AccessModifierDeclarations

  # retrieve a Hash of transport schemas, keyed by their name.
  def list
    init_transports
    Marshal.load(Marshal.dump(@transports[@environment]))
  end
  module_function :list # rubocop:disable Style/AccessModifierDeclarations

  def connect(name, connection_info)
    validate(name, connection_info)
    require "puppet/transport/#{name}"
    class_name = name.split('_').map { |e| e.capitalize }.join
    # passing the copy as it may have been stripped on invalid key/values by validate
    Puppet::Transport.const_get(class_name).new(get_context(name), connection_info)
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
    init_transports
    require "puppet/transport/schema/#{name}" unless @transports[@environment].key? name
    transport_schema = @transports[@environment][name]
    if transport_schema.nil?
      raise Puppet::DevError, 'Transport for `%{target}` not registered with `%{environment}`' % {
        target: name,
        environment: @environment,
      }
    end

    transport_schema.check_schema(connection_info)
    transport_schema.validate(connection_info)
  end
  private_class_method :validate

  def self.get_context(name)
    require 'puppet/resource_api/puppet_context'
    Puppet::ResourceApi::PuppetContext.new(@transports[@environment][name])
  end
  private_class_method :get_context

  def self.init_transports
    lookup = Puppet.lookup(:current_environment) if Puppet.respond_to? :lookup
    @environment =  if lookup.nil?
                      :transports_default
                    else
                      lookup.name
                    end
    @transports ||= {}
    @transports[@environment] ||= {}
  end
  private_class_method :init_transports
end
