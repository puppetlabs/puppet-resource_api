# 1. Test the resource api against jruby as well as ruby engines

Date: 2024-06-17

## Status

Accepted

## Context

Since the Resource API runs inside the puppetserver, then we must test the `resource_api` against the JRuby versions we ship.  These require special dependencies to have everything load properly.  For example, rubocop 1.48 supports JRuby 9.3+, which includes coverage for versions we support.

## Decision

Therefore, always include `jruby` test environments matching the version included in our puppetserver releases.

## Consequences

`jruby` variants of the `resource_api` in production will be tested in CI.
