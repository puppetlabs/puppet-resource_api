# frozen_string_literal: true

module Puppet; end # rubocop:disable Style/Documentation

module Puppet::ResourceApi
  # This class provides a default implementation for set(), when your resource does not benefit from batching.
  # Instead of processing changes yourself, the `create`, `update`, and `delete` functions, are called for you,
  # with proper logging already set up.
  # Note that your type needs to use `ensure` in the conventional way with values of `prsesent`
  # and `absent` to signal presence and absence of resources.
  class SimpleProvider
    def set(context, changes)
      namevars = context.type.namevars

      changes.each do |name, change|
        is = if context.type.feature?('simple_get_filter')
               change.key?(:is) ? change[:is] : (get(context, [name]) || []).find { |r| SimpleProvider.build_name(namevars, r) == name }
             else
               change.key?(:is) ? change[:is] : (get(context) || []).find { |r| SimpleProvider.build_name(namevars, r) == name }
             end
        context.type.check_schema(is) unless change.key?(:is)

        should = change[:should]

        raise 'SimpleProvider cannot be used with a Type that is not ensurable' unless context.type.ensurable?

        is_ensure = is.nil? ? 'absent' : is[:ensure].to_s
        should_ensure = should.nil? ? 'absent' : should[:ensure].to_s

        name_hash = if namevars.length > 1
                      # pass a name_hash containing the values of all namevars
                      name_hash = {}
                      namevars.each do |namevar|
                        name_hash[namevar] = change[:should][namevar]
                      end
                      name_hash
                    else
                      name
                    end

        if is_ensure == 'absent' && should_ensure == 'present'
          context.creating(name) do
            create(context, name_hash, should)
          end
        elsif is_ensure == 'present' && should_ensure == 'absent'
          context.deleting(name) do
            delete(context, name_hash)
          end
        elsif is_ensure == 'present'
          context.updating(name) do
            update(context, name_hash, should)
          end
        end
      end
    end

    def create(_context, _name, _should)
      raise "#{self.class} has not implemented `create`"
    end

    def update(_context, _name, _should)
      raise "#{self.class} has not implemented `update`"
    end

    def delete(_context, _name)
      raise "#{self.class} has not implemented `delete`"
    end

    # @api private
    def self.build_name(namevars, resource_hash)
      if namevars.size > 1
        Hash[namevars.map { |attr| [attr, resource_hash[attr]] }]
      else
        resource_hash[namevars[0]]
      end
    end
  end
end
