require 'puppet/resource_api/transport'
require 'hocon'
require 'hocon/config_syntax'

# Puppet::ResourceApi::Transport::Wrapper` to interface between the Util::NetworkDevice
class Puppet::ResourceApi::Transport::Wrapper
  attr_reader :transport, :schema

  def initialize(name, url_or_config)
    if url_or_config.is_a? String
      url = URI.parse(url_or_config)
      raise "Unexpected url '#{url_or_config}' found. Only file:/// URLs for configuration supported at the moment." unless url.scheme == 'file'
      raise "Trying to load config from '#{url.path}, but file does not exist." if url && !File.exist?(url.path)
      config = self.class.deep_symbolize(Hocon.load(url.path, syntax: Hocon::ConfigSyntax::HOCON) || {})
    else
      config = url_or_config
    end

    @transport = Puppet::ResourceApi::Transport.connect(name, config)
    @schema = Puppet::ResourceApi::Transport.list[name]
  end

  def facts
    context = Puppet::ResourceApi::PuppetContext.new(@schema)
    # @transport.facts + custom_facts  # look into custom facts work by TP
    @transport.facts(context)
  end

  def respond_to_missing?(name, _include_private)
    (@transport.respond_to? name) || super
  end

  def method_missing(method_name, *args, &block)
    if @transport.respond_to? method_name
      @transport.send(method_name, *args, &block)
    else
      super
    end
  end

  # From https://stackoverflow.com/a/11788082/4918
  def self.deep_symbolize(obj)
    return obj.each_with_object({}) { |(k, v), memo| memo[k.to_sym] = deep_symbolize(v); } if obj.is_a? Hash
    return obj.each_with_object([]) { |v, memo| memo << deep_symbolize(v); } if obj.is_a? Array
    obj
  end
end
