require 'yaml'

module Puppet; end # rubocop:disable Style/Documentation
module Puppet::ResourceApi
  # A trivial class to provide the functionality required to push data through the existing type/provider parts of puppet
  class TypeShim
    attr_reader :values, :typename, :namevars, :attr_def

    def initialize(resource_hash, typename, namevars, attr_def)
      # internalize and protect - needs to go deeper
      @values = resource_hash.dup.freeze

      @typename = typename
      @namevars = namevars
      @attr_def = attr_def
      @resource = ResourceShim.new(@values, @typename, @namevars, @attr_def)
    end

    def to_resource
      @resource
    end

    def name
      @resource.title
    end
  end

  # A trivial class to provide the functionality required to push data through the existing type/provider parts of puppet
  class ResourceShim
    attr_reader :values, :typename, :namevars, :attr_def

    def initialize(resource_hash, typename, namevars, attr_def)
      @values = resource_hash.dup.freeze # whatevs
      @typename = typename
      @namevars = namevars
      @attr_def = attr_def
    end

    def title
      values[:title] || values[@namevars.first]
    end

    def prune_parameters(*_args)
      # puts "not pruning #{args.inspect}" if args.length > 0
      self
    end

    def to_manifest
      (["#{@typename} { #{Puppet::Parameter.format_value_for_display(title)}: "] + filtered_keys.map do |k|
        cs = ' '
        ce = ''
        if attr_def[k] && attr_def[k][:behaviour] && attr_def[k][:behaviour] == :read_only
          cs = '#'
          ce = ' # Read Only'
        end
        "#{cs} #{k} => #{Puppet::Parameter.format_value_for_display(values[k])},#{ce}"
      end + ['}']).join("\n")
    end

    # Convert our resource to yaml for Hiera purposes.
    def to_hierayaml
      attributes = Hash[filtered_keys.map { |k| [k.to_s, values[k]] }]
      YAML.dump('type' => { title => attributes }).split("\n").drop(2).join("\n") + "\n"
    end

    # attribute names that are not title or namevars
    def filtered_keys
      values.keys.reject { |k| k == :title || !attr_def[k] || (attr_def[k][:behaviour] == :namevar && @namevars.size == 1) }
    end
  end
end
