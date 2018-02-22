
module Puppet::ResourceApi
  # A trivial class to provide the functionality required to push data through the existing type/provider parts of puppet
  class TypeShim
    attr_reader :values, :typename

    def initialize(title, resource_hash, typename)
      # internalize and protect - needs to go deeper
      @values        = resource_hash.dup
      # "name" is a privileged key
      @values[:name] = title
      @typename = typename
      @values.freeze
    end

    def to_resource
      ResourceShim.new(@values, @typename)
    end

    def name
      values[:name]
    end
  end

  # A trivial class to provide the functionality required to push data through the existing type/provider parts of puppet
  class ResourceShim
    attr_reader :values, :typename

    def initialize(resource_hash, typename)
      @values = resource_hash.dup.freeze # whatevs
      @typename = typename
    end

    def title
      values[:name]
    end

    def prune_parameters(*_args)
      # puts "not pruning #{args.inspect}" if args.length > 0
      self
    end

    def to_manifest
      (["#{@typename} { #{values[:name].inspect}: "] + values.keys.reject { |k| k == :name }.map { |k| "  #{k} => #{Puppet::Parameter.format_value_for_display(values[k])}," } + ['}']).join("\n")
    end

    # Convert our resource to yaml for Hiera purposes.
    def to_hierayaml
      (["  #{values[:name]}: "] + values.keys.reject { |k| k == :name }.map { |k| "    #{k}: #{Puppet::Parameter.format_value_for_display(values[k])}" }).join("\n") + "\n"
    end
  end
end
