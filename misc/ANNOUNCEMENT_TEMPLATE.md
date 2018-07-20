Send out announcements for major new feature releases, and high-impact bugfixes to <puppet-announce@googlegroups.com>, <puppet-dev@googlegroups.com>, <puppet-users@googlegroups.com>, <voxpupuli@groups.io>, and the puppet internal mailing lists <dev@puppet.com> and <tech-discuss@puppet.com>.

Before sending, do check that all links are still valid. Feel free to adjust the text to match better with the circumstances of the release, or add other news that are relevant at the time. If you make changes, consider committing them here, for the benefit of future-you.

The github rendering of the markdown seems to copy&paste acceptably into Google Inbox.

The [CHANGELOG](https://github.com/puppetlabs/puppet-resource_api/blob/master/CHANGELOG.md) is a good starting point for finding enhancements and bug-fixes.

See [this post](https://groups.google.com/d/msg/puppet-dev/1R9gwkEIxHU/adWXJ0NfCAAJ) for an example.

---

Subject: [ANN] Resource API vX.Y.Z Release

Hi all,

We're pleased to announce that version X.Y.Z of the Resource API is being released today.

The Resource API provides a simple way to create new native resources in the form of types and providers for Puppet. Using a little bit of ruby, you can finally get rid of that brittle exec, or manage that one API that eluded you until now.

It is provided as a Ruby gem to be referenced within modules. Support for it has been included as an experimental feature in the Puppet Development Kit (see `pdk new provider --help`). Use the [resource_api module](https://forge.puppet.com/puppetlabs/resource_api) or the [puppet 6 nightly packages](https://groups.google.com/d/msg/puppet-users/N3LJGhsrqkU/TUEsq7VfDQAJ) to deploy it in your infrastructure.

The new release of the Resource API provides the following enhancements:

* A
* B
* C

The new release also contains the following notable bugfixes:

* D
* E
* F

See the [CHANGELOG](https://github.com/puppetlabs/puppet-resource_api/blob/master/CHANGELOG.md) for a full list of changes.

We encourage all module developers to review the Resource API and use it when creating types and providers. The [README](https://github.com/puppetlabs/puppet-resource_api/blob/master/README.md) gets you going quickly. To see some example code see [this simple Philips Hue type](https://github.com/da-ar/hue_rsapi) or [this experimental apt_key provider](https://github.com/DavidS/puppetlabs-apt/blob/resource-api-experiments/lib/puppet/provider/apt_key2/apt_key2.rb).

Please let us know of your experiences with the Resource API, either here, on [Slack](https://slack.puppet.com/) (#forge-modules), or on the [github repo](https://github.com/puppetlabs/puppet-resource_api).


Thanks,
YOUR NAME
