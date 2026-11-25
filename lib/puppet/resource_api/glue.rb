# frozen_string_literal: true

module Puppet; end # rubocop:disable Style/Documentation

module Puppet::ResourceApi
  # A trivial class to provide the functionality required to push data through the existing type/provider parts of puppet
  class ResourceShim
    attr_reader :values, :typename, :namevars, :attr_def, :catalog

    def initialize(resource_hash, typename, namevars, attr_def, catalog = nil)
      @values = resource_hash.dup.freeze # whatevs
      @typename = typename
      @namevars = namevars
      @attr_def = attr_def
      @catalog = catalog
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
        "#{cs} #{k} => #{Puppet::Parameter.format_value_for_display(values[k])},#{ce}" unless values[k].nil?
      end + ['}']).compact.join("\n")
    end

    # Required to enable the `puppet resource ... --to_yaml` and
    # `puppet device --resource ... --to_yaml` workflows: Puppet merges the
    # hashes of all resources and dumps the result as YAML. Like
    # Puppet::Resource#to_hiera_hash, return plain data that can be fed back
    # through Hiera: no read-only, unset or sensitive attributes (their value
    # cannot be exported), values converted to Puppet data, ensure first and
    # the other attributes sorted.
    def to_hiera_hash
      keys = filtered_keys.reject do |k|
        values[k].nil? || attr_def[k][:behaviour] == :read_only || attr_def[k][:sensitive] == true || sensitive?(values[k])
      end
      keys = keys.sort_by { |k| [k == :ensure ? 0 : 1, k.to_s] }
      attributes = keys.to_h { |k| [k.to_s, values[k]] }
      { title.to_s => Puppet::Pops::Serialization::ToStringifiedConverter.convert(attributes) }
    end

    def to_json(*)
      attrs = filtered_keys.map { |k| [k.to_s, values[k]] unless values[k].nil? }
      attributes = Hash[*attrs.compact.flatten]
      resource = { title => attributes }
      resource.to_json
    end

    def to_hash
      values
    end

    # attribute names that are not title, namevars, or rsapi_custom_insync_trigger
    def filtered_keys
      values.keys.reject { |k| k == :title || k == :rsapi_custom_insync_trigger || !attr_def[k] || (attr_def[k][:behaviour] == :namevar && @namevars.size == 1) }
    end

    private

    # whether the value is or contains a Sensitive, which cannot be exported
    def sensitive?(value)
      case value
      when Puppet::Pops::Types::PSensitiveType::Sensitive then true
      when Array then value.any? { |v| sensitive?(v) }
      when Hash then value.any? { |k, v| sensitive?(k) || sensitive?(v) }
      else false
      end
    end
  end

  # this hash allows key-value based ordering comparisons between instances of this and instances of this and other classes
  # this is required for `lib/puppet/indirector/resource/ral.rb`'s `search` method which expects all titles to be comparable
  class MonkeyHash < Hash
    def <=>(other)
      result = self.class.name <=> other.class.name
      result = keys.sort <=> other.keys.sort if result.zero?
      result = keys.sort.map { |k| self[k] } <=> other.keys.sort.map { |k| other[k] } if result.zero?
      result
    end
  end
end
