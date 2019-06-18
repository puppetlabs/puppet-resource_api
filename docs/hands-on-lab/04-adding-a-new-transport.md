# Add a new transport

[Eventually](https://github.com/puppetlabs/pdk/pull/666) there will be a `pdk new transport` command. For now, you'll need to copy the files below.

Copy the files from [this directory](./04-adding-a-new-transport/) into your new module:

* .sync.yml
* lib/puppet/transport/hue.rb
* lib/puppet/transport/schema/hue.rb
* lib/puppet/util/network_device/hue/device.rb
* spec/unit/puppet/transport/hue_spec.rb
* spec/unit/puppet/transport/schema/hue_spec.rb

Run `pdk update --force` to enable a few future defaults that are required for these templates:

```
david@davids:~/tmp/hue$ pdk update --force
pdk (INFO): Updating david-hue using the default template, from master@c43fc26 to master@c43fc26

----------Files to be modified----------
Gemfile
spec/spec_helper.rb

----------------------------------------

You can find a report of differences in update_report.txt.

[✔] Resolving default Gemfile dependencies.

------------Update completed------------

2 files modified.

david@davids:~/tmp/hue$
```

## Checkpoint

To validate your new module and transport, run `pdk validate --parallel` and `pdk test unit`:

```
david@davids:~/tmp/hue$ pdk validate --parallel
pdk (INFO): Running all available validators...
pdk (INFO): Using Ruby 2.5.5
pdk (INFO): Using Puppet 6.4.2
┌ [✔] Validating module using 5 threads ┌
├──[✔] Checking metadata syntax (metadat├──son tasks/*.json).
├──[✔] Checking task names (tasks/**/*).├──
└──[✔] Checking YAML syntax (["**/*.yaml├──"*.yaml", "**/*.yml", "*.yml"]).
└──[/] Checking module metadata style (metadata.json).
└──[✔] Checking module metadata style (metadata.json).
info: puppet-syntax: ./: Target does not contain any files to validate (**/*.pp).
info: task-metadata-lint: ./: Target does not contain any files to validate (tasks/*.json).
info: puppet-lint: ./: Target does not contain any files to validate (**/*.pp).
david@davids:~/tmp/hue$ pdk test unit
pdk (INFO): Using Ruby 2.5.5
pdk (INFO): Using Puppet 6.4.2
[✔] Preparing to run the unit tests.
[✔] Running unit tests in parallel.
Run options: exclude {:bolt=>true}
  Evaluated 6 tests in 2.405066937 seconds: 0 failures, 0 pending.
david@davids:~/tmp/hue$
```

If you're working with a version control system, now would be a good time to make your first commit and store the boilerplate code, and then you can revisit the changes you made later. For example: 

```
david@davids:~/tmp/hue$ git init
Initialized empty Git repository in ~/tmp/hue/.git/
david@davids:~/tmp/hue$ git add -A
david@davids:~/tmp/hue$ git commit -m 'initial commit'
[master (root-commit) 67951dd] initial commit
 26 files changed, 887 insertions(+)
 create mode 100644 .fixtures.yml
 create mode 100644 .gitattributes
 create mode 100644 .gitignore
 create mode 100644 .gitlab-ci.yml
 create mode 100644 .pdkignore
 create mode 100644 .puppet-lint.rc
 create mode 100644 .rspec
 create mode 100644 .rubocop.yml
 create mode 100644 .sync.yml
 create mode 100644 .travis.yml
 create mode 100644 .yardopts
 create mode 100644 CHANGELOG.md
 create mode 100644 Gemfile
 create mode 100644 README.md
 create mode 100644 Rakefile
 create mode 100644 appveyor.yml
 create mode 100644 data/common.yaml
 create mode 100644 hiera.yaml
 create mode 100644 lib/puppet/transport/hue.rb
 create mode 100644 lib/puppet/transport/schema/hue.rb
 create mode 100644 lib/puppet/util/network_device/hue/device.rb
 create mode 100644 metadata.json
 create mode 100644 spec/default_facts.yml
 create mode 100644 spec/spec_helper.rb
 create mode 100644 spec/unit/puppet/transport/hue_spec.rb
 create mode 100644 spec/unit/puppet/transport/schema/hue_spec.rb
david@davids:~/tmp/hue$
```

## Next up

Now that you have everything ready, you'll [implement the transport](./05-implementing-the-transport.md).
