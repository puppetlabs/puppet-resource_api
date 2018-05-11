require 'puppet/resource_api'

# Implementation for the title_provider type using the Resource API.
class Puppet::Provider::MultipleNamevar::MultipleNamevar

  def initialize
    defaults = [
      { package: 'php', manager: 'yum', ensure: 'present' },
      { package: 'php', manager: 'gem', ensure: 'present' },
      { package: 'mysql', manager: 'yum', ensure: 'present' },
      { package: 'mysql', manager: 'gem', ensure: 'present' },
      { package: 'foo', manager: 'bar', ensure: 'present' },
      { package: 'bar', manager: 'foo', ensure: 'present' },
    ]
    @current_values ||= defaults
  end

  def set(context, changes)
    changes.each do |name, change|
        if change[:is] != change[:should]

          match = @current_values.find do |item|
            context.type.namevars.all? do |namevar|
              item[namevar] == change[:should][namevar]
            end
          end
          match[:ensure] = change[:should][:ensure] if match

        Puppet.notice("Unable to find matching resource.") if match.nil?
        end
    end
    @current_values
  end

  def get(_context)
    @current_values
  end
end
