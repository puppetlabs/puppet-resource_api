# pathspec-ruby

[![Gem Version](https://badge.fury.io/rb/pathspec.svg)](https://badge.fury.io/rb/pathspec) [![Build Status](https://travis-ci.org/highb/pathspec-ruby.svg?branch=master)](https://travis-ci.org/highb/pathspec-ruby) [![Maintainability](https://api.codeclimate.com/v1/badges/4f3b5917e01fb34f790d/maintainability)](https://codeclimate.com/github/highb/pathspec-ruby/maintainability)

[Supported Rubies](https://www.ruby-lang.org/en/downloads/):

- 2.4.6 (Maintenance)
- 2.5.6 (Stable)
- 2.6.4 (Stable)

Match Path Specifications, such as .gitignore, in Ruby!

Follows .gitignore syntax defined on [gitscm](http://git-scm.com/docs/gitignore)

.gitignore functionality ported from [Python pathspec](https://pypi.python.org/pypi/pathspec/0.2.2) by [@cpburnz](https://github.com/cpburnz/python-path-specification)

## Build/Install from Rubygems

```shell
gem install pathspec
```

## CLI Usage

```bash
➜  test-pathspec cat .gitignore
*.swp
/coverage/
➜  test-pathspec be pathspec-rb specs_match "coverage/foo"
/coverage/
➜  test-pathspec be pathspec-rb specs_match "file.swp"
*.swp
➜ test-pathspec be pathspec-rb match "file.swp"
➜ test-pathspec echo $?
0
➜  test-pathspec ls
Gemfile      Gemfile.lock coverage     file.swp     source.rb
➜  test-pathspec be pathspec-rb tree .
./coverage
./coverage/index.html
./file.swp
```

## Usage

```ruby
require 'pathspec'

# Create a .gitignore-style Pathspec by giving it newline separated gitignore
# lines, an array of gitignore lines, or any other enumable object that will
# give strings matching the .gitignore-style (File, etc.)
gitignore = Pathspec.from_filename('spec/files/gitignore_readme')

# Our .gitignore in this example contains:
# !**/important.txt
# abc/**

# true, matches "abc/**"
gitignore.match 'abc/def.rb'
# CLI equivalent: pathspec.rb -f spec/files/gitignore_readme match 'abc/def.rb'

# false, because it has been negated using the line "!**/important.txt"
gitignore.match 'abc/important.txt'
# CLI equivalent: pathspec.rb -f spec/files/gitignore_readme match 'abc/important.txt'

# Give a path somewhere in the filesystem, and the Pathspec will return all
# matching files underneath.
# Returns ['/src/repo/abc/', '/src/repo/abc/123']
gitignore.match_tree '/src/repo'
# CLI equivalent: pathspec.rb -f spec/files/gitignore_readme tree /src/repo

# Give an enumerable of paths, and Pathspec will return the ones that match.
# Returns ['/abc/123', '/abc/']
gitignore.match_paths ['/abc/123', '/abc/important.txt', '/abc/']
# There is no CLI equivalent to this.
```

## Building/Installing from Source

```shell
git clone git@github.com:highb/pathspec-ruby.git
cd pathspec-ruby && bash ./build_from_source.sh
```

## Contributing

Pull requests, bug reports, and feature requests welcome! :smile: I've tried to write exhaustive tests but who knows what cases I've missed.
