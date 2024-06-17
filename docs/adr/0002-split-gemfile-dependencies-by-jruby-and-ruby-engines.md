# 2. Split Gemfile dependencies by jruby and ruby engines

Date: 2024-06-17

## Status

Accepted

## Context

Rubocop recently updated it's gems and broke CI across many of our repositories, including the `resource_api`:

* The error was `Error: Property AutoCorrect of cop FactoryBot/CreateList is supposed to be a boolean and contextual is not.`  See [here](#context-details) for more information.
* Updating the `Gemfile` with new rubocop versions like [here](#gemfile-update) fixed all repositories except for `resource_api`.  In particular the the `jruby` runners threw an error like: `rubocop (~> 1.64.1) was resolved to 1.64.1, which depends on Ruby (>= 2.7.0)`

Before landing on a solution I tried the following:

* I adjusted the rubocop versions aiming to get one set that would work for all environments (`jruby 9.3.7.0`, `jruby 9.4.2.0`, `ruby 2.7`, and `ruby 3.2`).   However, this never worked for me because when I got group working, like `jruby`, then the other group, i,e. `ruby`, broke.  
* I pinned the rubocop versions to the last working nightly CI versions, but this also failed.

Finally--and to aid in troubleshooting--I tried separating the Gemfile dependencies for `jruby` vs `ruby`.  For ruby I kept the latest rubocop versions, but for jruby I kept the versions that worked on the last successful nightly:

```ruby
  if RUBY_ENGINE == 'jruby'
    gem 'rubocop', '~> 1.48.1', require: false
    gem 'rubocop-rspec', '~> 2.20.0', require: false
    gem 'rubocop-performance', '~> 1.17.1', require: false
  else
    gem 'rubocop', '~> 1.64.1', require: false
    gem 'rubocop-rspec', '~> 3.0', require: false
    gem 'rubocop-performance', '~> 1.16', require: false
  end
```

## Decision

Therefore, I decided to use the `if RUBY_ENGINE == 'jruby'` solution to get our CI working again.

## Consequences

The main advantage of this approach is that all of the ruby engine environments are now working.  As the `jruby` environments are included in our puppet enterprise products it is essential that these continue passing.

One disadvantage is that the `jruby` rubocop is pinned to old versions of rubocop and further breakages may occur in the `jruby` environments.  For example, I observed that `NewCops` added to the `.rubocop_todo.yml` by my ruby setup, broke the jruby one.  The following error occurred on `jruby` setups until I corrected these errors and removed them from the `.rubocop_todo.yml`:

```ruby
➜  puppet_7_jruby_9.3.7.0 git:(cat_1910_fix_nightlies) ✗ be rubocop
+ bundle exec rubocop
Error: unrecognized cop or department RSpec/MetadataStyle found in .rubocop_todo.yml
Did you mean `RSpec/DuplicatedMetadata`?
unrecognized cop or department RSpec/ReceiveMessages found in .rubocop_todo.yml
Did you mean `RSpec/ReceiveNever`?
unrecognized cop or department RSpec/RedundantPredicateMatcher found in .rubocop_todo.yml
Did you mean `RSpec/DuplicatedMetadata`?
unrecognized cop or department Style/RedundantRegexpArgument found in .rubocop_todo.yml
Did you mean `Style/RedundantRegexpEscape`, `Style/RedundantArgument`, `Style/RedundantSelfAssignment`?
unrecognized cop or department Style/SuperArguments found in .rubocop_todo.yml
Did you mean `Style/PerlBackrefs`?
+ set +x
➜  puppet_7_jruby_9.3.7.0 git:(cat_1910_fix_nightlies) ✗ 
```

## Apendix

### Gemfile update

From this

```ruby
gem 'rubocop', '~> 1.48.1', require: false
gem 'rubocop-rspec', '~> 2.19', require: false
```

to this

```ruby
gem 'rubocop', '~> 1.64.1', require: false
gem 'rubocop-rspec', '~> 3.0', require: false
```
### Context Details

* Rubocop recently updated it's gems and broke CI across many of our repositories, including the `resource_api`, with an error like the following:

```bash
➜  puppet-resource_api git:(main) bundle exec rubocop
Error: Property AutoCorrect of cop FactoryBot/CreateList is supposed to be a boolean and contextual is not.
+ set +x
➜  puppet-resource_api git:(main) 
```

* Updating the `Gemfile` with new rubocop versions like [here](#gemfile-update) fixed all repositories except for `resource_api`.  In particular the the `jruby` runners threw an error like:

```ruby
➜  puppet_7_jruby_9.3.7.0 git:(cat_1910_fix_nightlies) ✗ bundle install
Fetching gem metadata from https://rubygems.org/.........
Resolving dependencies.....
Bundler found conflicting requirements for the Ruby version:
  In Gemfile:
    Ruby

    ffi (= 1.15.5) was resolved to 1.15.5, which depends on
      Ruby (>= 2.3)

    puppet was resolved to 7.31.0, which depends on
      Ruby (>= 2.5.0)

    rubocop (~> 1.64.1) was resolved to 1.64.1, which depends on
      Ruby (>= 2.7.0)
➜  puppet_7_jruby_9.3.7.0 git:(cat_1910_fix_nightlies) ✗ 
```
