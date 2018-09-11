require 'puppet/resource_api'

# Implementation for the title_provider type using the Resource API.
class Puppet::Provider::CompositeNamevar::CompositeNamevar
  def initialize
    @current_values ||= [
      { title: 'php-yum', package: 'php', manager: 'yum', ensure: 'present', value: 'a' },
      { title: 'php-gem', package: 'php', manager: 'gem', ensure: 'present', value: 'b' },
      { title: 'mysql-yum', package: 'mysql', manager: 'yum', ensure: 'present', value: 'c' },
      { title: 'mysql-gem', package: 'mysql', manager: 'gem', ensure: 'present', value: 'd' },
      { title: 'foo-bar', package: 'foo', manager: 'bar', ensure: 'present', value: 'e' },
      { title: 'bar-foo', package: 'bar', manager: 'foo', ensure: 'present', value: 'f' },
    ]
  end

  def set(context, changes)
    changes.each do |name, change|
      next unless change[:is] != change[:should]

      match = @current_values.find do |item|
        context.type.namevars.all? do |namevar|
          item[namevar] == change[:should][namevar]
        end
      end
      if match
        match[:ensure] = change[:should][:ensure]
      else
        context.created([name], message: 'Adding new record')
        @current_values << change[:should].dup
      end
    end
  end

  def get(_context)
    @current_values
  end
end
