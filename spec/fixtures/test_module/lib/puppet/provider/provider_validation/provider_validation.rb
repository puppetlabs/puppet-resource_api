require 'puppet/resource_api'

# Implementation for the provider_validation type using the Resource API.
class Puppet::Provider::ProviderValidation::ProviderValidation
  def get(_context)
    [
      {
        name: 'a',
        string: 'hello',
        boolean: true,
        integer: 1,
        float: 1.2,
        variant_pattern: '0xABABABAB',
        url: 'http://www.puppet.com',
        optional_string: '',
        optional_int: 1,
        # no failures
      },
      {
        name: 'b',
        string: 1, # fail
        boolean: true,
        integer: 1,
        float: 1.2,
        variant_pattern: '0xABABABAB',
        url: 'http://www.puppet.com',
        optional_string: '',
        optional_int: 1
      },
      {
        name: 'c',
        string: 'hello',
        boolean: 'true', # fail
        integer: 1,
        float: 1.2,
        variant_pattern: '0xABABABAB',
        url: 'http://www.puppet.com',
        optional_string: '',
        optional_int: 1
      },
      {
        name: 'd',
        string: 'hello',
        boolean: true,
        integer: 'one', # fail
        float: 1.2,
        variant_pattern: '0xABABABAB',
        url: 'http://www.puppet.com',
        optional_string: '',
        optional_int: 1
      },
      {
        name: 'e',
        string: 'hello',
        boolean: true,
        integer: 1,
        float: false, # fail
        variant_pattern: '0xABABABAB',
        url: 'http://www.puppet.com',
        optional_string: '',
        optional_int: 1
      },
      {
        name: 'f',
        string: 'hello',
        boolean: true,
        integer: 1,
        float: 1.2,
        variant_pattern: '0xABABABABAB', # fail
        url: 'http://www.puppet.com',
        optional_string: '',
        optional_int: 1
      },
      {
        name: 'g',
        string: 'hello',
        boolean: true,
        integer: 1,
        float: 1.2,
        variant_pattern: '0xABABABAB',
        url: 'meep', # fail
        optional_string: '',
        optional_int: 1
      },
      {
        name: 'h',
        string: 'hello',
        boolean: true,
        integer: 1,
        float: 1.2,
        variant_pattern: '0xABABABAB',
        url: 'http://www.puppet.com',
        optional_string: 11, # fail,
        optional_int: 1
      },
      {
        name: 'i',
        string: 'hello',
        boolean: true,
        integer: 1,
        float: 1.2,
        variant_pattern: '0xABABABAB',
        url: 'http://www.puppet.com',
        optional_int: 'omega', # fail
      },
      {
        name: 'j',
        string: 'hello',
        boolean: true,
        integer: 1,
        float: 1.2,
        variant_pattern: '0xABABABAB',
        url: 'http://www.puppet.com',
        optional_string: '',
        optional_int: 1,
        wibble: 'foo', # fail
      }
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
end
