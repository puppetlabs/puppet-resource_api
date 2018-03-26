# Changelog

All significant changes to this repo will be summarized in this file.


## [v1.0.2](https://github.com/puppetlabs/puppet-resource_api/tree/v1.0.2) (2018-03-26)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.0.1...v1.0.2)

**Implemented enhancements:**

- \(PDK-875\) Validate behaviour values when registering a type [\#49](https://github.com/puppetlabs/puppet-resource_api/pull/49) ([da-ar](https://github.com/da-ar))

**Fixed bugs:**

- \(PDK-882,PDK-883\) validate only when needed [\#48](https://github.com/puppetlabs/puppet-resource_api/pull/48) ([DavidS](https://github.com/DavidS))
- \(PDK-884\) Handle missing namevars returned by providers [\#47](https://github.com/puppetlabs/puppet-resource_api/pull/47) ([da-ar](https://github.com/da-ar))

**Merged pull requests:**

- \(PDK-810\) run CI against all the versions [\#46](https://github.com/puppetlabs/puppet-resource_api/pull/46) ([DavidS](https://github.com/DavidS))

## [v1.0.1](https://github.com/puppetlabs/puppet-resource_api/tree/v1.0.1) (2018-03-23)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v1.0.0...v1.0.1)

**Fixed bugs:**

- Actually implement the promised behavior [\#44](https://github.com/puppetlabs/puppet-resource_api/pull/44) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Release prep for v1.0.1 [\#45](https://github.com/puppetlabs/puppet-resource_api/pull/45) ([DavidS](https://github.com/DavidS))
- Release prep for v1.0.0 [\#43](https://github.com/puppetlabs/puppet-resource_api/pull/43) ([da-ar](https://github.com/da-ar))

## [v1.0.0](https://github.com/puppetlabs/puppet-resource_api/tree/v1.0.0) (2018-03-23)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.10.0...v1.0.0)

**Implemented enhancements:**

- Improve logging output [\#42](https://github.com/puppetlabs/puppet-resource_api/pull/42) ([DavidS](https://github.com/DavidS))
- \(PDK-797\) Render read\_only values as comments in manifest output [\#41](https://github.com/puppetlabs/puppet-resource_api/pull/41) ([da-ar](https://github.com/da-ar))

**Fixed bugs:**

- \(PDK-819\) Ensure checks for mandatory type attributes [\#40](https://github.com/puppetlabs/puppet-resource_api/pull/40) ([da-ar](https://github.com/da-ar))

**Merged pull requests:**

- Notes on how to build a release [\#39](https://github.com/puppetlabs/puppet-resource_api/pull/39) ([DavidS](https://github.com/DavidS))
- Release prep for v0.10.0 [\#38](https://github.com/puppetlabs/puppet-resource_api/pull/38) ([DavidS](https://github.com/DavidS))

## [v0.10.0](https://github.com/puppetlabs/puppet-resource_api/tree/v0.10.0) (2018-03-21)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.9.0...v0.10.0)

**Implemented enhancements:**

- \(PDK-512\) Add support for simple\_get\_filter [\#37](https://github.com/puppetlabs/puppet-resource_api/pull/37) ([da-ar](https://github.com/da-ar))
- \(PDK-822\) Implement proper namevar handling [\#36](https://github.com/puppetlabs/puppet-resource_api/pull/36) ([DavidS](https://github.com/DavidS))
- \(PDK-513\) implement `supports\_noop` [\#31](https://github.com/puppetlabs/puppet-resource_api/pull/31) ([DavidS](https://github.com/DavidS))
- \(PDK-511\) Add canonicalization checking if puppet strict is on. [\#30](https://github.com/puppetlabs/puppet-resource_api/pull/30) ([da-ar](https://github.com/da-ar))
- \(PDK-508\) implement autorequire and friends [\#29](https://github.com/puppetlabs/puppet-resource_api/pull/29) ([DavidS](https://github.com/DavidS))
- Update README with PDK 1.4 commands and messages [\#28](https://github.com/puppetlabs/puppet-resource_api/pull/28) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Cleanups [\#34](https://github.com/puppetlabs/puppet-resource_api/pull/34) ([DavidS](https://github.com/DavidS))
- Cleanup test module [\#33](https://github.com/puppetlabs/puppet-resource_api/pull/33) ([DavidS](https://github.com/DavidS))
- Update to rubocop 0.53.0 [\#32](https://github.com/puppetlabs/puppet-resource_api/pull/32) ([DavidS](https://github.com/DavidS))

## [v0.9.0](https://github.com/puppetlabs/puppet-resource_api/tree/v0.9.0) (2018-02-22)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.3.0...v0.9.0)

**Implemented enhancements:**

- \(PDK-536\) Proper datatype parsing and checking [\#23](https://github.com/puppetlabs/puppet-resource_api/pull/23) ([DavidS](https://github.com/DavidS))

**Fixed bugs:**

- SimpleProvider: fix `is`-lookup and docs [\#24](https://github.com/puppetlabs/puppet-resource_api/pull/24) ([DavidS](https://github.com/DavidS))
- \(main\) Fixup to\_manifest output [\#20](https://github.com/puppetlabs/puppet-resource_api/pull/20) ([shermdog](https://github.com/shermdog))

**Merged pull requests:**

- Release prep v0.9.0 [\#27](https://github.com/puppetlabs/puppet-resource_api/pull/27) ([DavidS](https://github.com/DavidS))
- Add a note on device support to the README [\#26](https://github.com/puppetlabs/puppet-resource_api/pull/26) ([DavidS](https://github.com/DavidS))
- Remove Command API [\#25](https://github.com/puppetlabs/puppet-resource_api/pull/25) ([DavidS](https://github.com/DavidS))

## [v0.3.0](https://github.com/puppetlabs/puppet-resource_api/tree/v0.3.0) (2018-02-21)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.2.2...v0.3.0)

**Implemented enhancements:**

- \(FM-6797\) Add debug logging of current and target states [\#21](https://github.com/puppetlabs/puppet-resource_api/pull/21) ([da-ar](https://github.com/da-ar))
- \(PDK-803\) Add YAML output for resources [\#19](https://github.com/puppetlabs/puppet-resource_api/pull/19) ([shermdog](https://github.com/shermdog))
- Edits on resource api readme [\#17](https://github.com/puppetlabs/puppet-resource_api/pull/17) ([clairecadman](https://github.com/clairecadman))

**Fixed bugs:**

- \(PDK-569\) `puppet resource` now displays type name correctly [\#18](https://github.com/puppetlabs/puppet-resource_api/pull/18) ([tphoney](https://github.com/tphoney))

**Merged pull requests:**

- Release prep v0.3.0 [\#22](https://github.com/puppetlabs/puppet-resource_api/pull/22) ([DavidS](https://github.com/DavidS))

## [v0.2.2](https://github.com/puppetlabs/puppet-resource_api/tree/v0.2.2) (2018-01-25)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.2.1...v0.2.2)

**Fixed bugs:**

- make the server parts JRuby compatible [\#15](https://github.com/puppetlabs/puppet-resource_api/pull/15) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Release prep v0.2.2 [\#16](https://github.com/puppetlabs/puppet-resource_api/pull/16) ([DavidS](https://github.com/DavidS))

## [v0.2.1](https://github.com/puppetlabs/puppet-resource_api/tree/v0.2.1) (2018-01-24)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.2.0...v0.2.1)

**Fixed bugs:**

- gemspec fixes [\#12](https://github.com/puppetlabs/puppet-resource_api/pull/12) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Release prep [\#14](https://github.com/puppetlabs/puppet-resource_api/pull/14) ([DavidS](https://github.com/DavidS))

## [v0.2.0](https://github.com/puppetlabs/puppet-resource_api/tree/v0.2.0) (2018-01-23)
[Full Changelog](https://github.com/puppetlabs/puppet-resource_api/compare/v0.1.0...v0.2.0)

**Implemented enhancements:**

-  \(PDK-703\) Resource API introduction with pdk [\#11](https://github.com/puppetlabs/puppet-resource_api/pull/11) ([DavidS](https://github.com/DavidS))
- \(PDK-746\) have a SimpleProvider for simple cases [\#8](https://github.com/puppetlabs/puppet-resource_api/pull/8) ([DavidS](https://github.com/DavidS))

**Fixed bugs:**

- Fix params and properties [\#10](https://github.com/puppetlabs/puppet-resource_api/pull/10) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- Release Prep for 0.2.0 [\#9](https://github.com/puppetlabs/puppet-resource_api/pull/9) ([DavidS](https://github.com/DavidS))
- Small fixes [\#7](https://github.com/puppetlabs/puppet-resource_api/pull/7) ([DavidS](https://github.com/DavidS))

## [v0.1.0](https://github.com/puppetlabs/puppet-resource_api/tree/v0.1.0) (2017-11-17)
**Merged pull requests:**

- \(maint\) sort dependencies in gemspec [\#6](https://github.com/puppetlabs/puppet-resource_api/pull/6) ([DavidS](https://github.com/DavidS))
- base\_context processing and processed logging methods [\#5](https://github.com/puppetlabs/puppet-resource_api/pull/5) ([james-stocks](https://github.com/james-stocks))
- Fix resource\_api logging format [\#4](https://github.com/puppetlabs/puppet-resource_api/pull/4) ([james-stocks](https://github.com/james-stocks))
- Add logging action methods to base\_context [\#3](https://github.com/puppetlabs/puppet-resource_api/pull/3) ([james-stocks](https://github.com/james-stocks))
- Logging [\#2](https://github.com/puppetlabs/puppet-resource_api/pull/2) ([james-stocks](https://github.com/james-stocks))
- Workaround missing report back from here to flush\(\) [\#1](https://github.com/puppetlabs/puppet-resource_api/pull/1) ([james-stocks](https://github.com/james-stocks))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*