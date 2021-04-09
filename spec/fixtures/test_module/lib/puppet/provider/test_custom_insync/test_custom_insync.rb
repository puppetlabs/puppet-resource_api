require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'

# Implementation for the test_bool type using the Resource API.
class Puppet::Provider::TestCustomInsync::TestCustomInsync < Puppet::ResourceApi::SimpleProvider
  def get(_context)
    [
      {
        name: 'example',
        ensure: 'present',
        some_array: ['a', 'b'],
        case_sensitive_string: 'FooBar',
        case_insensitive_string: 'FooBar',
        version: '1.2.3',
      },
      {
        name: 'dependent',
        ensure: 'present',
        some_array: ['a', 'b'],
        case_sensitive_string: 'FooBar',
        case_insensitive_string: 'FooBar',
        version: '1.2.3',
      },
    ]
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
  end

  def version_insync?(context, is_hash, should_hash)
    if should_hash[:version] == ''
      if should_hash[:minimum_version] || should_hash[:maximum_version]
        context.notice('Checking a min/max version')
        meets_minimum_expectation = Gem::Version.new(is_hash[:version]) >= Gem::Version.new(should_hash[:minimum_version]) unless should_hash[:minimum_version].nil?
        meets_maximum_expectation = Gem::Version.new(is_hash[:version]) <= Gem::Version.new(should_hash[:maximum_version]) unless should_hash[:maximum_version].nil?
        if should_hash[:minimum_version] && should_hash[:maximum_version]
          return meets_minimum_expectation && meets_maximum_expectation ? true : "The actual version (#{is_hash[:version]}) does not meet the combined minimum (#{should_hash[:minimum_version]}) and maximum (#{should_hash[:maximum_version]}) bounds; updating to a version which does."
        elsif should_hash[:minimum_version]
          return meets_minimum_expectation ? true : "The actual version (#{is_hash[:version]}) does not meet the minimum version bound (#{should_hash[:minimum_version]}); updating to a version that does"
        else
          return meets_maximum_expectation ? true : "The actual version (#{is_hash[:version]}) does not meet the maximum version bound (#{should_hash[:maximum_version]}); updating to a version that does"
        end
      else
        return true
      end
    elsif !should_hash[:version].nil? && should_hash[:version].match?(%r{^\D+\s+})
      context.notice("Checking a custom version bound")
      return Gem::Dependency.new('', should_hash[:version]).match?('', is_hash[:version]) ? true : "The actual version (#{is_hash[:version]}) does not meet the custom version bound (#{should_hash[:version]}); updating to a version that does"
    end
  end

  def insync?(context, name, property_name, is_hash, should_hash)
    context.notice("Checking whether #{property_name} is out of sync")
    case property_name
    when :some_array
      if should_hash[:force]
        context.notice("Checking an order independent array")
        return is_hash[property_name].sort == should_hash[property_name].sort
      else
        context.notice("Checking a subset match array")
        found_members = (is_hash[property_name] & should_hash[property_name]).sort
        missing_members = should_hash[property_name].reject { |member| found_members.include?(member) }
        return missing_members.empty? ? true : "Adding missing members #{missing_members}"
      end
    when :case_insensitive_string
      # Need to show what happens when a comparison fails
      raise "FAILURE MODE ENGAGED WITH #{property_name} set to '#{should_hash[property_name]}'" if should_hash[property_name].downcase == 'raiseerror'
      return is_hash[property_name].downcase == should_hash[property_name].downcase
    when :version
      return version_insync?(context, is_hash, should_hash)
    end
  end
end
