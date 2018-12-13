# Remote target transport API
module Puppet::ResourceApi::Transport
  def register(schema)
    raise Puppet::DevError, 'requires a hash as schema, not `%{other_type}`' % { other_type: schema.class } unless schema.is_a? Hash
    raise Puppet::DevError, 'requires a `:name`' unless schema.key? :name
    raise Puppet::DevError, 'requires `:desc`' unless schema.key? :desc
    raise Puppet::DevError, 'requires `:connection_info`' unless schema.key? :connection_info
    raise Puppet::DevError, '`:connection_info` must be a hash, not `%{other_type}`' % { other_type: schema[:connection_info].class } unless schema[:connection_info].is_a?(Hash)

    @transports ||= {}
    raise Puppet::DevError, 'Transport `%{name}` is already registered.' % { name: schema[:name] } unless @transports[schema[:name]].nil?
    @transports[schema[:name]] = Puppet::ResourceApi::TransportSchemaDef.new(schema)
  end
  module_function :register # rubocop:disable Style/AccessModifierDeclarations
end
