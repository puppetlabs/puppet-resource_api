
module Puppet::ResourceApi
  # A trivial class to provide the functionality required to push data through the existing type/provider parts of puppet
  class TypeShim
    attr_reader :values, :typename, :namevar

    def initialize(title, resource_hash, typename, namevarname)
      # internalize and protect - needs to go deeper
      @values = resource_hash.dup
      # "name" is a privileged key
      @values[namevarname] = title
      @values.freeze

      @typename = typename
      @namevar = namevarname
    end

    def to_resource
      ResourceShim.new(@values, @typename, @namevar)
    end

    def name
      values[@namevar]
    end
  end

  # A trivial class to provide the functionality required to push data through the existing type/provider parts of puppet
  class ResourceShim
    attr_reader :values, :typename, :namevar

    def initialize(resource_hash, typename, namevarname)
      @values = resource_hash.dup.freeze # whatevs
      @typename = typename
      @namevar = namevarname
    end

    def title
      values[@namevar]
    end

    def prune_parameters(*_args)
      # puts "not pruning #{args.inspect}" if args.length > 0
      self
    end

    def to_manifest
      (["#{@typename} { #{values[@namevar].inspect}: "] + values.keys.reject { |k| k == @namevar }.map { |k| "  #{k} => #{Puppet::Parameter.format_value_for_display(values[k])}," } + ['}']).join("\n")
    end

    # Convert our resource to yaml for Hiera purposes.
    def to_hierayaml
      (["  #{values[@namevar]}: "] + values.keys.reject { |k| k == @namevar }.map { |k| "    #{k}: #{Puppet::Parameter.format_value_for_display(values[k])}" }).join("\n") + "\n"
    end
  end
end
