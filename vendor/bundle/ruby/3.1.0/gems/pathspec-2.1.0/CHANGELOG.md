# pathspec-ruby CHANGELOG

## 2.1.0

## refactor/perf

- Add missing frozen_string_literal comments to reduce object allocations

## build

- Updated Rubocop to 1.18.3
- Fixed/re-enabled Rubocop
- Updated fakefs to 1.3
- Cleaned up unnecessary spec files from the Gem

Thanks for the above contributions @ericproulx! #50

## 2.0.0

- (Maint) Remove deprecated/security release versions of Ruby. The Gem will now only support and be tested against >= 3.1.0 e.g. 3.1, 3.2, and 3.3.

## 1.1.3 (Patch/Bug Fix Release)

- Fixed Man page generation bug in GH Actions

## 1.1.1 (Patch/Bug Fix Release)

- (Maint) Updated Supported Ruby Versions (>= 2.6.9 is the earliest supported now)
- (Maint) Linting corrections
- Setup a CI system with GH Actions to do better validation of the gem before release.

## 1.1.0 (Minor Release)

:alert: This release was mis-tagged. Use 1.1.1 instead. :alert:

- (Maint) Updated Supported Ruby Versions
- (Maint) Linting corrections

## 1.0.0 (Major Release)

- Adds a required ruby version of 2.6 (reason for major version bump)
- Adds man/html docs

## 0.2.1 (Patch/Bug Fix Release)

- Fixes incorrectly pushed gem on Rubygems.org

## 0.2.0 (Minor Release)

- (Feature) A CLI tool, pathspec-rb, is now provided with the gem.
- (API Change) New namespace for gem: `PathSpec`: Everything is now namespaced under `PathSpec`, to prevent naming collisions with other libraries. Thanks @tenderlove!
- (License) License version updated to Apache 2. Thanks @kytrinyx!
- (Maint) Pruned Supported Ruby Versions. We now test: 2.2.9, 2.3.6 and 2.4.3.
- (Maint) Ruby 2.5.0 testing is blocked on Travis, but should work locally. Thanks @SumLare!
- (Maint) Added Rubocop and made some corrections

## 0.1.2 (Patch/Bug Fix Release)

- Fix for regexp matching Thanks @incase! #16
- File handling cleanup Thanks @martinandert! #13
- `from_filename` actually works now! Thanks @martinandert! #12

## 0.1.0 (Minor Release)

- Port new edgecase handling from [python-path-specification](https://github.com/cpburnz/python-path-specification/pull/8). Many thanks to @jdpace! :)
- Removed EOL Ruby support
- Added current Ruby stable to Travis testing

## 0.0.2 (Patch/Bug Fix Release)

- Fixed issues with Ruby 1.8.7/2.1.1
- Added more testing scripts
- Fixed Windows path related issues
- Cleanup unnecessary things in gem

## 0.0.1

- Initial version.
