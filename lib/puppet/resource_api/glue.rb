
module Puppet::ResourceApi
  # A trivial class to provide the functionality required to push data through the existing type/provider parts of puppet
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

  # A trivial class to provide the functionality required to push data through the existing type/provider parts of puppet
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
      # TODO: get the correct typename here
      (["SOMETYPE { #{values[:name].inspect}: "] + values.keys.reject { |k| k == :name }.map { |k| "  #{k} => #{values[k].inspect}," } + ['}']).join("\n")
    end
  end
end
