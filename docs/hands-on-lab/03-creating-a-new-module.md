# Create a module

Depending on your preferences, you can use the VSCode/PDK integration or run PDK from the command line in a terminal of your choice.

## Create a module with VSCode

Spin up the Command Palette (⇧⌘P on the Mac or Ctrl+Shift+P on Windows and Linux) and search for the `Puppet: PDK New Module` task:

![](./03-creating-a-new-module_vscode.png)

Click Enter (↩) to execute this and follow the on-screen prompts.

The module will open in a new VSCode window.

## Create a module from the command line

In your regular workspace (for example your home directory), run the following:

```
pdk new module hue_workshop --skip-interview
```

This command creates a new module `hue_workshop` in your directory of the same name, using all defaults. The output will look like:

```
david@davids:~/tmp$ pdk new module hue_workshop --skip-interview
pdk (INFO): Creating new module: hue_workshop
pdk (INFO): Module 'hue_workshop' generated at path '/home/david/tmp/hue_workshop', from template 'file:///opt/puppetlabs/pdk/share/cache/pdk-templates.git'.
pdk (INFO): In your module directory, add classes with the 'pdk new class' command.
david@davids:~/tmp$ ls hue_workshop/
appveyor.yml  data      files    Gemfile.lock  manifests      Rakefile   spec   templates
CHANGELOG.md  examples  Gemfile  hiera.yaml    metadata.json  README.md  tasks
david@davids:~/tmp$
```

To read more about the different options when creating new modules, see [PDK docs](https://puppet.com/docs/pdk/1.x/pdk_creating_modules.html).

Open the new directory in your code editor:

```
code -a hue_workshop
```

Next, we'll active a few future defaults. In the `hue_workshop` directory, create a file called `.sync.yml` and paste the following:

```
# .sync.yml
---
Gemfile:
  optional:
    ':development':
      - gem: 'puppet-resource_api'
      - gem: 'faraday'
      - gem: 'rspec-json_expectations'
spec/spec_helper.rb:
  mock_with: ':rspec'
```

Run `pdk update` in the module's directory to deploy the changes in the module:

```
david@davids:~/tmp/hue_workshop$ pdk update
pdk (INFO): Updating david-hue_workshop using the default template, from 1.10.0 to 1.10.0

----------Files to be modified----------
Gemfile
spec/spec_helper.rb

----------------------------------------

You can find a report of differences in update_report.txt.

Do you want to continue and make these changes to your module? Yes

------------Update completed------------

2 files modified.

david@davids:~/tmp/hue_workshop$
```


## Next up

Now that you have created a module, you'll [add a transport](./04-adding-a-new-transport.md).
