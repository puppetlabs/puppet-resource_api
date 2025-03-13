# RSpec tests for your Puppet manifests & modules

[![Code Owners](https://img.shields.io/badge/owners-DevX--team-blue)](https://github.com/puppetlabs/rspec-puppet/blob/main/CODEOWNERS)
![ci](https://github.com/puppetlabs/rspec-puppet/actions/workflows/ci.yml/badge.svg)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/puppetlabs/rspec-puppet)

#### Table of Contents

* [Installation](#installation)
* [Starting out with a new module](#starting-out-with-a-new-module)
* [Configuration](#configuration)
* [Naming conventions](#naming-conventions)
* [Example groups](#example-groups)
* [Defined Types and Classes](#defined-types-and-classes)
* [Functions](#functions)
* [Hiera integration](#hiera-integration)
* [Producing coverage reports](#producing-coverage-reports)
* [Related projects](#related-projects)
* [Development](#development)
* [License](#license)

## Installation

    gem install rspec-puppet

## Starting out with a new module

When you start out on a new module, create a metadata.json file for your module and then run `rspec-puppet-init` to create the necessary files to configure rspec-puppet for your module's tests.

Configuration is typically done in a `spec/spec_helper.rb` file which each of your spec will require. Example code:

```ruby
RSpec.configure do |c|
  c.module_path     = File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures', 'modules')
  c.environmentpath = File.join(Dir.pwd, 'spec')
  c.manifest        = File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures', 'manifests', 'site.pp')
  # Coverage generation
  c.after(:suite) do
    RSpec::Puppet::Coverage.report!
  end
end
```

## Configuration

rspec-puppet can be configured by modifying the `RSpec.configure` block in your
`spec/spec_helper.rb` file.

```ruby
RSpec.configure do |c|
  c.<config option> = <value>
end
```

#### module\_path
Type   | Default  | Puppet Version(s)
------ | -------- | ------------------
String | Required | any

The path to the directory containing your Puppet modules.

#### default\_facts
Type | Default | Puppet Version(s)
---- | ------- | ------------------
Hash | `{}`    | any

A hash of default facts that should be used for all the tests.

#### hiera\_config
Type   | Default       | Puppet Version(s)
------ | ------------- | -----------------
String | `"/dev/null"` | any

The path to your `hiera.yaml` file (if used).

#### manifest
Type   | Default                | Puppet Version(s)
------ | ---------------------- | -----------------
String | Puppet's default value | any

Path to test manifest. Typically `spec/fixtures/manifests/site.pp`.

#### default\_node\_params
Type | Default | Puppet Version(s)
---- | ------- | -----------------
Hash | `{}`    | any

A hash of default node parameters that should be used for all the tests.

#### default\_trusted\_facts
Type | Default | Puppet Version(s)
---- | ------- | -----------------
Hash | `{}`    | any

A hash of default trusted facts that should be used for all the tests
(available in the manifests as the `$trusted` hash).

#### confdir
Type   | Default         | Puppet Version(s)
------ | --------------- | ------------------
String | `"/etc/puppet"` | any

The path to the main Puppet configuration directory.

#### config
Type   | Default                | Puppet Version(s)
------ | ---------------------- | ------------------
String | Puppet's default value | any

The path to `puppet.conf`.

#### environmentpath
Type   | Default                               | Puppet Version(s)
------ | ------------------------------------- | -----------------
String | `"/etc/puppetlabs/code/environments"` | any

The search path for environment directories.

#### strict\_variables
Type    | Default | Puppet Version(s)
------- | ------- | -----------------
Boolean | `false` | any

Makes Puppet raise an error when it tries to reference a variable that hasn't
been defined (not including variables that have been explicitly set to
`undef`).

#### stringify\_facts
Type    | Default | Puppet Version(s)
------- | ------- | -----------------
Boolean | `true`  | any

Makes rspec-puppet coerce all the fact values into strings (matching the
behaviour of older versions of Puppet).

#### enable\_pathname\_stubbing
Type    | Default | Puppet Version(s)
------- | ------- | ------------------
Boolean |`false`  | any

Configures rspec-puppet to stub out `Pathname#absolute?` with it's own
implementation. This should only be enabled if you're running into an issue
running cross-platform tests where you have Ruby code (types, providers,
functions, etc) that use `Pathname#absolute?`.

#### setup\_fixtures
Type    | Default | Puppet Version(s)
------- | ------- | ------------------
Boolean | `true`  | any

Configures rspec-puppet to automatically create a link from the root of your
module to `spec/fixtures/<module name>` at the beginning of the test run.

#### derive\_node\_facts\_from\_nodename
Type    | Default | Puppet Version(s)
------- | ------- | -----------------
Boolean | `true`  | any

If `true`, rspec-puppet will override the `fdqn`, `hostname`, and `domain`
facts with values that it derives from the node name (specified with
`let(:node)`.

In some circumstances (e.g. where your nodename/certname is not the same as
your FQDN), this behaviour is undesirable and can be disabled by changing this
setting to `false`.

#### facter\_implementation
Type    | Default  | Puppet Version(s)
------- | -------- | -----------------
String  | `facter` | any

Configures rspec-puppet to use a specific Facter implementation for running
unit tests. If the `rspec` implementation is set and Puppet does not support
it, rspec-puppet will warn and fall back to the `facter` implementation.
Setting an unsupported option will make rspec-puppet raise an error.

 * `facter` - Use the default implementation, honoring the Facter version specified in the Gemfile
 * `rspec` - Use a custom hash-based implementation of Facter defined in
   rspec-puppet (this provides a considerable gain in speed if tests are run with Facter 4)

## Naming conventions

For clarity and consistency, I recommend that you use the following directory
structure and naming convention.

    module/
      ├── manifests/
      ├── lib/
      └── spec/
           ├── spec_helper.rb
           │
           ├── classes/
           │     └── <class_name>_spec.rb
           │
           ├── defines/
           │     └── <define_name>_spec.rb
           │
           ├── functions/
           │     └── <function_name>_spec.rb
           │
           ├── types/
           │     └── <type_name>_spec.rb
           │
           ├── type_aliases/
           │     └── <type_alias_name>_spec.rb
           │
           └── hosts/
                 └── <host_name>_spec.rb

## Example groups

If you use the above directory structure, your examples will automatically be
placed in the correct groups and have access to the custom matchers.  *If you
choose not to*, you can force the examples into the required groups as follows.

```ruby
describe 'myclass', :type => :class do
  ...
end

describe 'mydefine', :type => :define do
  ...
end

describe 'myfunction', :type => :puppet_function do
  ...
end

describe 'mytype', :type => :type do
  ...
end

describe 'My::TypeAlias', :type => :type_alias do
  ...
end

describe 'myhost.example.com', :type => :host do
  ...
end
```

## Defined Types and Classes

### Matchers

#### Checking if the catalog compiles

You can test whether the subject catalog compiles cleanly with `compile`.

```ruby
it { is_expected.to compile }
```

To check the error messages of your class, you can check for raised error messages.

```ruby
it { is_expected.to compile.and_raise_error(/error message match/) }
```

#### Checking if a resource exists

You can test if a resource exists in the catalogue with the generic
`contain_<resource type>` matcher.

```ruby
it { is_expected.to contain_augeas('bleh') }
```

You can also test if a class has been included in the catalogue with the
same matcher.

```ruby
it { is_expected.to contain_class('foo') }
```

Note that rspec-puppet does none of the class name parsing and lookup that the puppet parser would do for you. The matcher only accepts fully qualified classnames without any leading colons. That is a class `foo::bar` will only be matched by `foo::bar`, but not by `::foo::bar`, or `bar` alone.

If your resource type includes :: (e.g.
`foo::bar` simply replace the :: with __ (two underscores).

```ruby
it { is_expected.to contain_foo__bar('baz') }
```

You can further test the parameters that have been passed to the resources with
the generic `with_<parameter>` chains.

```ruby
it { is_expected.to contain_package('mysql-server').with_ensure('present') }
```

If you want to specify that the given parameters should be the only ones passed
to the resource, use the `only_with_<parameter>` chains.

```ruby
it { is_expected.to contain_package('httpd').only_with_ensure('latest') }
```

You can use the `with` method to verify the value of multiple parameters.

```ruby
it do
  is_expected.to contain_service('keystone').with(
    'ensure'     => 'running',
    'enable'     => 'true',
    'hasstatus'  => 'true',
    'hasrestart' => 'true'
  )
end
```

The same holds for the `only_with` method, which in addition verifies the exact
set of parameters and values for the resource in the catalogue.

```ruby
it do
  is_expected.to contain_user('luke').only_with(
    'ensure' => 'present',
    'uid'    => '501'
  )
end
```

You can also test that specific parameters have been left undefined with the
generic `without_<parameter>` chains.

```ruby
it { is_expected.to contain_file('/foo/bar').without_mode }
```

You can use the without method to verify that a list of parameters have not been
defined

```ruby
it { is_expected.to contain_service('keystone').without(
  ['restart', 'status']
)}
```

#### Checking the number of resources

You can test the number of resources in the catalogue with the
`have_resource_count` matcher.

```ruby
it { is_expected.to have_resource_count(2) }
```

The number of classes in the catalogue can be checked with the
`have_class_count` matcher.

```ruby
it { is_expected.to have_class_count(2) }
```

You can also test the number of a specific resource type, by using the generic
`have_<resource type>_resource_count` matcher.

```ruby
it { is_expected.to have_exec_resource_count(1) }
```

This last matcher also works for defined types. If the resource type contains
::, you can replace it with __ (two underscores).

```ruby
it { is_expected.to have_logrotate__rule_resource_count(3) }
```

*NOTE*: when testing a class, the catalogue generated will always contain at
least one class, the class under test. The same holds for defined types, the
catalogue generated when testing a defined type will have at least one resource
(the defined type itself).

#### Relationship matchers

The following methods will allow you to test the relationships between the resources in your catalogue, regardless of how the relationship is defined. This means that it doesn’t matter if you prefer to define your relationships with the metaparameters (**require**, **before**, **notify** and **subscribe**) or the chaining arrows (**->**, **~>**, **<-** and **<~**), they’re all tested the same.

```ruby
it { is_expected.to contain_file('foo').that_requires('File[bar]') }
it { is_expected.to contain_file('foo').that_comes_before('File[bar]') }
it { is_expected.to contain_file('foo').that_notifies('File[bar]') }
it { is_expected.to contain_file('foo').that_subscribes_to('File[bar]') }
```

An array can be used to test a resource for multiple relationships

```ruby
it { is_expected.to contain_file('foo').that_requires(['File[bar]', 'File[baz]']) }
it { is_expected.to contain_file('foo').that_comes_before(['File[bar]','File[baz]']) }
it { is_expected.to contain_file('foo').that_notifies(['File[bar]', 'File[baz]']) }
it { is_expected.to contain_file('foo').that_subscribes_to(['File[bar]', 'File[baz]']) }
```

You can also test the reverse direction of the relationship, so if you have the following bit of Puppet code

```ruby
notify { 'foo': }
notify { 'bar':
  before => Notify['foo'],
}
```

You can test that **Notify[bar]** comes before **Notify[foo]**

```ruby
it { is_expected.to contain_notify('bar').that_comes_before('Notify[foo]') }
```
Or, you can test that **Notify[foo]** requires **Notify[bar]**

```ruby
it { is_expected.to contain_notify('foo').that_requires('Notify[bar]') }
```

##### Match target syntax

Note that this notation does not support any of the features you're used from the puppet language. Only a single resource with a single, unquoted title can be referenced here. Class names need to be always fully qualified and not have the leading `::`. It currently does not support inline arrays or quoting.

These work
* `Notify[foo]`
* `Class[profile::apache]`

These will not work
* `Notify['foo']`
* `Notify[foo, bar]`
* `Class[::profile::apache]`

##### Recursive dependencies

The relationship matchers are recursive in two directions:

* vertical recursion, which checks for dependencies with parents of the resource
 (i.e. the resource is contained, directly or not, in the class involved in the relationship).
 E.g. where `Package['foo']` comes before `File['/foo']`:

```puppet
class { 'foo::install': } ->
class { 'foo::config': }

class foo::install {
  package { 'foo': }
}

class foo::config {
  file { '/foo': }
}
```

* horizontal recursion, which follows indirect dependencies (dependencies of dependencies).
 E.g. where `Yumrepo['foo']` comes before `File['/foo']`:

```puppet
class { 'foo::repo': } ->
class { 'foo::install': } ->
class { 'foo::config': }

class foo::repo {
  yumrepo { 'foo': }
}

class foo::install {
  package { 'foo': }
}

class foo::config {
  file { '/foo': }
}
```

##### Autorequires

Autorequires are considered in dependency checks.

#### Type matcher

When testing custom types, the `be_valid_type` matcher provides a range of expectations:

* `with_provider(<provider_name>)`: check that the right provider was selected
* `with_properties(<property_list>)`: check that the specified properties are available
* `with_parameters(<parameter_list>)`: check that the specified parameters are available
* `with_features(<feature_list>)`: check that the specified features are available
* `with_set_attributes(<param_value_hash>)`: check that the specified attributes are set

#### Type alias matchers

When testing type aliases, the `allow_value` and `allow_values` matchers are used to check if the
alias accepts particular values or not:


```ruby
describe 'MyModule::Shape' do
  it { is_expected.to allow_value('square') }
  it { is_expected.to allow_values('circle', 'triangle') }
  it { is_expected.not_to allow_value('blue') }
end
```

### Writing tests

#### Basic test structure

To test that

    sysctl { 'baz'
      value => 'foo',
    }

Will cause the following resource to be in included in catalogue for a host

    exec { 'sysctl/reload':
      command => '/sbin/sysctl -p /etc/sysctl.conf',
    }

We can write the following testcase (in `spec/defines/sysctl_spec.rb`)

```ruby
describe 'sysctl' do
  let(:title) { 'baz' }
  let(:params) { { 'value' => 'foo' } }

  it { is_expected.to contain_exec('sysctl/reload').with_command("/sbin/sysctl -p /etc/sysctl.conf") }
end
```

#### Specifying the title of a resource

```ruby
let(:title) { 'foo' }
```

#### Specifying the parameters to pass to a resources or parameterised class

Parameters of a defined type or class can be passed defining `:params` in a let,
and passing it a hash as seen below.

```ruby
let(:params) { {'ensure' => 'present', ...} }
```

For passing Puppet's `undef` as a paremeter value, you can simply use `:undef` and it will
be translated to `undef` when compiling. For example:

```ruby
let(:params) { {'user' => :undef, ...} }
```

For passing a sensitive value you can use the sensitive function with a value in brackets. For example
```ruby
let(:params) { {'password' =>sensitive('secret') } }
```

For references to nodes or resources as seen when using `require` or `before` properties,
you can pass the string as an argument to the `ref` helper:

```ruby
let(:params) { 'require' => ref('Package', 'sudoku') }
```

Which translates to:

```puppet
mydefine { 'mytitle': require => Package['sudoku'] }
```

#### Specifying the FQDN of the test node

If the manifest you're testing expects to run on host with a particular name,
you can specify this as follows

```ruby
let(:node) { 'testhost.example.com' }
```

#### Specifying the environment name

If the manifest you're testing expects to evaluate the environment name,
you can specify this as follows

```ruby
let(:environment) { 'production' }
```

#### Specifying the facts that should be available to your manifest

By default, the test environment contains no facts for your manifest to use.
You can set them with a hash

```ruby
let(:facts) { {'operatingsystem' => 'Debian', 'kernel' => 'Linux', ...} }
```

Facts may be expressed as a value (shown in the previous example) or a structure.  Fact keys
may be expressed as either symbols or strings.  A key will be converted to a lower case
string to align with the Facter standard

```ruby
let(:facts) { {'os' => { 'family' => 'RedHat', 'release' => { 'major' => '7', 'minor' => '1', 'full' => '7.1.1503' } } } }
```

You can also create a set of default facts provided to all specs in your spec_helper:

``` ruby
RSpec.configure do |c|
  c.default_facts = {
    'operatingsystem' => 'Ubuntu'
  }
end
```

Any facts you provide with `let(:facts)` in a spec will automatically be merged on top
of the default facts.

#### Specifying top-scope variables that should be available to your manifest

You can create top-scope variables much in the same way as an ENC.


```ruby
let(:node_params) { { 'hostgroup' => 'webservers', 'rack' => 'KK04', 'status' => 'maintenance' } }
```

You can also create a set of default top-scope variables provided to all specs in your spec_helper:

``` ruby
RSpec.configure do |c|
  c.default_node_params = {
    'owner'  => 'itprod',
    'site'   => 'ams4',
    'status' => 'live'
  }
end
```

#### Specifying extra code to load (pre-conditions)

If the manifest being tested relies on another class or variables to be set, these can be added via
a pre-condition. This code will be evaluated before the tested class.

```ruby
let(:pre_condition) { 'include other_class' }
```

This may be useful when testing classes that are modular, e.g. testing `apache::mod::foo` which
relies on a top-level `apache` class being included first.

The value may be a raw string to be inserted into the Puppet manifest, or an array of strings
(manifest fragments) that will be concatenated.

#### Specifying extra code to load (post-conditions)

In some cases, you may need to ensure that the code that you are testing comes
**before** another set of code. Similar to the `:pre_condition` hook, you can add
a `:post_condition` hook that will ensure that the added code is evaluated
**after** the tested class.

```ruby
let(:post_condition) { 'include other_class' }
```

This may be useful when testing classes that are modular, e.g. testing class
`do_strange_things::to_the_catalog` which must come before class ``foo``.

The value may be a raw string to be inserted into the Puppet manifest, or an
array of strings (manifest fragments) that will be concatenated.

#### Specifying the path to find your modules

I recommend setting a default module path by adding the following code to your
`spec_helper.rb`

```ruby
RSpec.configure do |c|
  c.module_path = '/path/to/your/module/dir'
end
```

However, if you want to specify it in each example, you can do so

```ruby
let(:module_path) { '/path/to/your/module/dir' }
```

#### Specifying trusted facts

The trusted facts hash will have the standard trusted fact keys
(certname, domain, and hostname) populated based on the node name (as set with `:node`).

By default, the test environment contains no custom trusted facts (as usually obtained
from certificate extensions) and found in the `extensions` key. If you need to test against
specific custom certificate extensions you can set those with a hash. The hash will then
be available in `$trusted['extensions']`

```ruby
let(:trusted_facts) { {'pp_uuid' => 'ED803750-E3C7-44F5-BB08-41A04433FE2E', '1.3.6.1.4.1.34380.1.2.1' => 'ssl-termination'} }
```

You can also create a set of default certificate extensions provided to all specs in your spec_helper:

```ruby
RSpec.configure do |c|
  c.default_trusted_facts = {
    'pp_uuid'                 => 'ED803750-E3C7-44F5-BB08-41A04433FE2E',
    '1.3.6.1.4.1.34380.1.2.1' => 'ssl-termination'
  }
end
```

#### Specifying trusted external data

The trusted facts hash will have an `external` key for trusted external data.

By default, the test environment contains no trusted external data (as usually obtained from
trusted external commands and found in the `external` key). If you need to test against specific
trusted external data you can set those with a hash. The hash will then be available in
`$trusted['external']`

```ruby
let(:trusted_external_data) { {'foo' => 'bar'} }
```

You can also create a set of default trusted external data provided to all specs in your spec_helper:

```ruby
RSpec.configure do |c|
  c.default_trusted_external_data = {
    'foo' => 'bar'
  }
end
```

#### Testing Exported Resources

You can test if a resource was exported from the catalogue by using the
`exported_resources` accessor in combination with any of the standard matchers.

You can use `exported_resources` as the subject of a child context:

```ruby
context 'exported resources' do
  subject { exported_resources }

  it { is_expected.to contain_file('foo') }
end
```

You can also use `exported_resources` directly in a test:

```ruby
it { expect(exported_resources).to contain_file('foo') }
```

## Functions

### Matchers

All of the standard RSpec matchers are available for you to use when testing
Puppet functions.

```ruby
it 'should be able to do something' do
  subject.execute('foo') == 'bar'
end
```

For your convenience though, a `run` matcher exists to provide easier to
understand test cases.

```ruby
it { is_expected.to run.with_params('foo').and_return('bar') }
```

### Writing tests

#### Basic test structure

```ruby
require 'spec_helper'

describe '<function name>' do
  ...
end
```

#### Specifying the name of the function to test

The name of the function must be provided in the top level description, e.g.

```ruby
describe 'split' do
```

#### Specifying the arguments to pass to the function

You can specify the arguments to pass to your function during the test(s) using
either the `with_params` chain method in the `run` matcher

```ruby
it { is_expected.to run.with_params('foo', 'bar', ['baz']) }
```

Or by using the `execute` method on the subject directly

```ruby
it 'something' do
  subject.execute('foo', 'bar', ['baz'])
end
```

#### Passing lambdas to the function

A lambda (block) can be passed to functions that support either a required or
optional lambda by passing a block to the `with_lambda` chain method in the
`run` matcher.

```ruby
it { is_expected.to run.with_lambda { |x| x * 2 }
```

#### Testing the results of the function

You can test the result of a function (if it produces one) using either the
`and_returns` chain method in the `run` matcher

```ruby
it { is_expected.to run.with_params('foo').and_return('bar') }
```

Or by using any of the existing RSpec matchers on the subject directly

```ruby
it 'something' do
  subject.execute('foo') == 'bar'
  subject.execute('baz').should be_an Array
end
```

#### Testing the errors thrown by the function

You can test whether the function throws an exception using either the
`and_raises_error` chain method in the `run` matcher

```ruby
it { is_expected.to run.with_params('a', 'b').and_raise_error(Puppet::ParseError) }
it { is_expected.not_to run.with_params('a').and_raise_error(Puppet::ParseError) }
```

Or by using the existing `raises_error` RSpec matcher

```ruby
it 'something' do
  expect { subject.execute('a', 'b') }.should raise_error(Puppet::ParseError)
  expect { subject.execute('a') }.should_not raise_error(Puppet::ParseError)
end
```

#### Accessing the parser scope where the function is running

Some complex functions require access to the current parser's scope, e.g. for
stubbing other parts of the system.

```ruby
context 'when called with top-scope vars foo and bar set' do
  before do
    # :lookupvar is the method on scope that puppet calls internally to
    # resolve the value of a variable.
    allow(scope).to receive(:lookupvar).and_call_original
    allow(scope).to receive(:lookupvar).with('::foo').and_return('Hello')
    allow(scope).to receive(:lookupvar).with('::bar').and_return('World')
  end

  it { is_expected.to run.with_params().and_return('Hello World') }
end
```

Note that this does not work when testing manifests which use custom functions. Instead,
you'll need to create a replacement function directly.

```ruby
before(:each) do
    Puppet::Parser::Functions.newfunction(:custom_function, :type => :rvalue) { |args|
        raise ArgumentError, 'expected foobar' unless args[0] == 'foobar'
        'expected value'
    }
end

```


## Hiera integration

At some point, you might want to make use of Hiera to bring in custom parameters for your class tests. In this section, we will
provide you with basic guidance to setup Hiera implementation within rspec testing. For more information on Hiera, you should
check our official [documentation](https://www.puppet.com/docs/puppet/latest/hiera.html).

### Configuration

The first step is to create the general hiera configuration file. Since we want this to be exclusive for testing, we recommend creating
it inside your spec folder. Something along the lines of `spec/fixtures/hiera/hiera-rspec.yaml`. It should look something like this:

```yaml
---
version: 5
defaults:               # Used for any hierarchy level that omits these keys.
  datadir: data         # This path is relative to hiera.yaml's directory.
  data_hash: yaml_data  # Use the built-in YAML backend.

hierarchy:
  - name: 'rspec'
    path: 'rspec-data.yaml'
```

It is often recommended to use dummy data during testing to avoid real values from being entangled. In order to create
these values, we will need a new file containing this data exclusively, normally existing within a subfolder called `data`, ending up with
`spec/fixtures/hiera/data/rspec-data.yaml`. Here is an example of its contents:

```yaml
---
# We will be using this data in later examples
message: 'Hello world!'
dummy:message2: 'foobar' # autoloaded parameter
```

Finally, we make the target class spec file load the Hiera config, at which point we will be able to freely access it:

```ruby
let(:hiera_config) { 'spec/fixtures/hiera/hiera-rspec.yaml' }
```

Or alternatively, you could load the hiera configuration in the spec_helper to ensure it is available through all test files:

```ruby
RSpec.configure do |c|
  c.hiera_config = 'spec/fixtures/hiera/hiera-rspec.yaml'
end
```

#### Test usage examples

Unlike with Hiera 3, Hiera 5 comes packaged with our Puppet agent and runs during Puppet runtime. This means that it is not really possible to
call the lookup function in the same way it previously worked. However, you can still test its functionality via dummy class instantiation:

The following test creates a dummny class that uses the lookup function within it. This should allow you to confirm that the lookup() function
works correctly (remember that this test uses your custom hiera parameters, and not your real ones).

```ruby
context 'dummy hiera test is implemented' do
      let(:pre_condition) do
        "class dummy($message) { }
         class { 'dummy': message => lookup('message') }"
      end
      let(:hiera_config) { 'spec/fixtures/hiera/hiera-rspec.yaml' } # Only needed if the config has not been established in spec_helper

      it { is_expected.to compile }

      it 'loads ntpserver from Hiera' do
        is_expected.to contain_class('dummy').with_message('Hello world!')
      end
    end
```

The next test ensures that autoloaded parameters work correctly within your classes:

```ruby
    context 'dummy hiera test is implemented a second time' do
      let(:pre_condition) do
        "class dummy($message2) { }
        include dummy"
      end
      let(:hiera_config) { 'spec/fixtures/hiera/hiera-rspec.yaml' } # Only needed if the config has not been established in spec_helper

      it { is_expected.to compile }

      it 'loads ntpserver from Hiera' do
        is_expected.to contain_class('dummy').with_message2('foobar')
      end
    end
```

**Please note:** In-module hiera data depends on having a correct metadata.json file. It is
strongly recommended that you use [metadata-json-lint](https://github.com/voxpupuli/metadata-json-lint)
to automatically check your metadata.json file before running rspec.

## Producing coverage reports

You can output a basic resource coverage report with the following in
your `spec_helper.rb`

```ruby
RSpec.configure do |c|
  c.after(:suite) do
    RSpec::Puppet::Coverage.report!
  end
end
```

This checks which Puppet resources have been explicitly checked as part
of the current test run and outputs both a coverage percentage and a
list of untouched resources.

A desired code coverage level can be provided. If this level is not achieved, a test failure will be raised.  This can be used with a CI service, such as Jenkins or Bamboo, to enforce code coverage.  The following example requires the code coverage to be at least 95%.

```ruby
RSpec.configure do |c|
  c.after(:suite) do
    RSpec::Puppet::Coverage.report!(95)
  end
end
```

Resources declared outside of the module being tested (i.e. forge dependencies)
are automatically removed from the coverage report.

## Related projects

* [puppetlabs_spec_helper](https://github.com/puppetlabs/puppetlabs_spec_helper): shared spec helpers to setup puppet
* Fact providers
  * [rspec-puppet-facts](https://github.com/voxpupuli/rspec-puppet-facts): Simplify your unit tests by looping on every supported Operating System and populating facts.

For a list of other module development tools see [DevX Tools](https://puppetlabs.github.io/content-and-tooling-team/tools/), or from our trusted Voxpupuli community [here](https://voxpupuli.org/plugins/).

## Reporting bugs or incorrect results

If you find a bug in Puppet Lint or its results, please create an issue in the repo issues tracker. Bonus points will be awarded if you also include a patch that fixes the issue.

## Development

If you run into an issue with this tool or would like to request a feature you can raise a PR with your suggested changes. Alternatively, you can raise a Github issue with a feature request or to report any bugs. Every other Tuesday the DevX team holds office hours in the Puppet Community Slack, where you can ask questions about this and any other supported tools. This session runs at 15:00 (GMT/BST) for about an hour.

If you have problems getting this tool up and running, please contact Support.

## License

This codebase is licensed under Apache 2.0. However, the open source dependencies included in this codebase might be subject to other software licenses such as AGPL, GPL2.0, and MIT.

## Thank you

Many thanks to the original author of rspec-puppet Tim Sharpe (@rodjek).
