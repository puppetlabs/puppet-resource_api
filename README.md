# Puppet::ResourceApi [![TravisCI Build Status](https://travis-ci.org/puppetlabs/puppet-resource_api.svg?branch=master)](https://travis-ci.org/puppetlabs/puppet-resource_api) [![Appveyor Build status](https://ci.appveyor.com/api/projects/status/8o9s1ax0hs8lm5fd/branch/master?svg=true)](https://ci.appveyor.com/project/puppetlabs/puppet-resource-api/branch/master)
 [![codecov](https://codecov.io/gh/puppetlabs/puppet-resource_api/branch/master/graph/badge.svg)](https://codecov.io/gh/puppetlabs/puppet-resource_api)

This is an implementation of the [Resource API](https://github.com/DavidS/puppet-specifications/blob/resourceapi/language/resource-api/README.md) proposal. Find a working example of a new-style provider in the [experimental puppetlabs-apt branch](https://github.com/DavidS/puppetlabs-apt/blob/resource-api-experiments/lib/puppet/provider/apt_key2/apt_key2.rb). There is also the corresponding [type](https://github.com/DavidS/puppetlabs-apt/blob/resource-api-experiments/lib/puppet/type/apt_key2.rb), [provider](https://github.com/DavidS/puppetlabs-apt/blob/resource-api-experiments/lib/puppet/provider/apt_key2/apt_key2.rb), and [new unit tests](https://github.com/DavidS/puppetlabs-apt/blob/resource-api-experiments/spec/unit/puppet/provider/apt_key2/apt_key2_spec.rb) for 100% coverage.

## Getting started

* Install the [PDK](https://puppet.com/download-puppet-development-kit).
  * As of Jan 2018, the required PDK features are still in development.
    See [PDK-506](https://tickets.puppetlabs.com/browse/PDK-506) for progress.

* Create a [new module](https://puppet.com/docs/pdk/latest/pdk_generating_modules.html) with the PDK, or work with an existing PDK-enabled module.

* Add the `puppet-resource_api` gem, and enable "modern" rspec-style mocking through the `.sync.yml`:

```
# .sync.yml
---
Gemfile:
  optional:
    ':development':
      - gem: 'puppet-resource_api'
spec/spec_helper.rb:
  mock_with: ':rspec'
```

*  Apply the changes by running `pdk convert`:

```
~/git/example$ ~/git/pdk/bin/pdk convert

----------Files to be modified----------
Gemfile
spec/spec_helper.rb

----------------------------------------

You can find a report of differences in convert_report.txt.

pdk (INFO): Module conversion is a potentially destructive action. Ensure that you have committed your module to a version control system or have a backup, and review the changes above before continuing.
Do you want to continue and make these changes to your module? Yes
[✔] Resolving Gemfile dependencies.

------------Convert completed-----------

2 files modified.

~/git/example$
```

* Create the required files for a new type and provider in the module with `pdk new provider <provider_name>`.

```
~/git/example$ pdk new provider foo
pdk (INFO): Creating '/home/david/git/example/lib/puppet/type/foo.rb' from template.
pdk (INFO): Creating '/home/david/git/example/lib/puppet/provider/foo/foo.rb' from template.
pdk (INFO): Creating '/home/david/git/example/spec/unit/puppet/provider/foo/foo_spec.rb' from template.
~/git/example$
```

The three generated files are the type, the actual implementation, and unit tests. The default template contains a trivial example, to demonstrate the basic workings of the Resource API. This allows the unit tests to run immediately after creating the provider:

```
~/git/example$ pdk test unit
[✔] Installing missing Gemfile dependencies.
[✔] Preparing to run the unit tests.
[✔] Running unit tests.
  Evaluated 5 tests in 0.018781355 seconds: 0 failures, 0 pending.
[✔] Cleaning up after running unit tests.
~/git/example$
```

### Writing the Type

The type contains the shape of your resources. The template renders the minimally necessary `name`, and `ensure` attributes. You can modify their description and the name's type to match your resource. Add more attributes as you see fit.

```ruby
# lib/puppet/type/foo.rb
require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'foo',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage ...
    EOS
  attributes:   {
    ensure:      {
      type:    'Enum[present, absent]',
      desc:    'Whether this apt key should be present or absent on the target system.',
      default: 'present',
    },
    name:        {
      type:      'String',
      desc:      'The name of the resource you want to manage.',
      behaviour: :namevar,
    },
  },
)
```

The following keys are available for defining attributes:
* `type`: the puppet 4 data type allowed in this attribute. You can use all [data types](https://puppet.com/docs/puppet/latest/lang_data_abstract.html#parent-types) matching `Scalar` and `Data`.
* `desc`: a string describing this attribute. This is used in creating the automated API docs with [puppet-strings](https://github.com/puppetlabs/puppet-strings).
* `default`: a default value that will be used by the runtime environment, whenever the caller doesn't specify a value for this attribute.
* `behaviour`/`behavior`: how the attribute behaves. Currently available values:
  * `namevar`: marks an attribute as part of the "primary key", or "identity" of the resource. A given set of namevar values needs to distinctively identify a instance.
  * `init_only`: this attribute can only be set during creation of the resource. Its value will be reported going forward, but trying to change it later will lead to an error. For example, the base image for a VM, or the UID of a user.
  * `read_only`: values for this attribute will be returned by `get()`, but `set()` is not able to change them. Values for this should never be specified in a manifest. For example the checksum of a file, or the MAC address of a network interface.
  * `parameter`: these attributes influence how the provider behaves, and cannot be read from the target system. For example, the target file on inifile, or credentials to access an API.

### Writing the Provider

The provider is the meat and bone of your new resource. It contains all the intelligence to read and enforce state. Here's the example generated by `pdk new provider`:

```ruby
require 'puppet/resource_api'
require 'puppet/resource_api/command'
require 'puppet/resource_api/simple_provider'

# Implementation for the foo type using the Resource API.
class Puppet::Provider::Foo::Foo < Puppet::ResourceApi::SimpleProvider
  def initialize
    @echo_cmd = Puppet::ResourceApi::Command.new 'echo'
  end

  def get(context)
    # nonsensical resource emulation for this example
    @echo_cmd.run(context).stdout.split('').each do |c|
      {
        name: c,
        ensure: :present,
      }
    end || []
  end

  def create(context, name, should)
    # nonsensical resource emulation for this example
    @echo_cmd.run(context, "create: #{name}, #{should.inspect}")
  end

  def update(context, name, should)
    # nonsensical resource emulation for this example
    @echo_cmd.run(context, "update: #{name}, #{should.inspect}")
  end

  def delete(context, name)
    # nonsensical resource emulation for this example
    @echo_cmd.run(context, "delete: #{name}")
  end
end
```

The optional `initialize` method can be used to set up state that is available throughout the execution of the catalog. This is most often used for locally acting providers to set up command helpers, or to establish a connection, when talking to a service (e.g. when managing a database).

The `get(context)` method returns a list of hashes describing the resources that are currently on the target system. The basic example would always return an empty list. Here is an example of some resources that could be returned from this:

```ruby
[
  {
    name: 'a',
    ensure: 'present',
  },
  {
    name: 'b',
    ensure: 'present',
  },
]
```

The `create`/`update`/`delete` methods get called by the `SimpleProvider` base-class to change the system as requested by the catalog. The `name` argument is the name of the resource being processed. `should` contains the attribute hash - in the same format as `get` returns - with the values in the catalog.

### Unit testing

The generated unit tests in `spec/unit/puppet/provider/foo_spec.rb` get automatically evaluated with `pdk test unit`. 

### Further Reading

The [Resource API](https://github.com/DavidS/puppet-specifications/blob/resourceapi/language/resource-api/README.md) describes the gory details of all capabilities of this gem.

This [Introduction to Testing Puppet Modules](https://www.netways.de/index.php?id=3445#c44135) talk describes rspec usage in more detail.

The [RSpec docs](https://relishapp.com/rspec) give a great overview over all the capabilities of rspec. 

Read [betterspecs](http://www.betterspecs.org/) for general guidelines on what's considered good specs.

## Known Issues

This gem is still under heavy development. This section is a living document of what's already done, and what items are still outstanding.

Already working:
* basic type and provider definition, using `name`, `desc`, and `attributes`
* the `canonicalize` and `remote_resource` features
* all the logging facilities
* executing the new provider under any of the following commands:
  * `puppet apply`
  * `puppet resource`
  * `puppet agent`
  * `puppet device` (if applicable)


There are still a few notable gaps between the implementation, and the specification:
* Only a single runtime environment (the puppet commands) is currently implemented.
* `auto*` definitions
* the Commands API is mostly implemented, but deployment is blocked on upstream work (PDK-580). You can use regular Ruby `system()` calls as a workaround, with all their underlying encoding, and safety issues.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/puppet-resource_api.
