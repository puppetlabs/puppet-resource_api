Send out announcements for major new feature releases and high-impact bugfixes.

For each release two announcements should be sent: an internal one and an external one.

Both emails must be sent from the puppet-product-updates@puppet.com email alias. You must add yourself to the alias in order to have rights to send the email from that alias.

### Internal email
Send from the puppet-product-updates@puppet.com email alias to the internal-puppet-product-updates email address. This will send the announcement to internal only people and most internal groups have been auto-subscribed to that list, so it should hit everyone in the organisation. It may include specific internal-only information, but most of the core content should be the same as the external email. Indeed, it is acceptable for both emails to be the same if there is no internal only information.

### External email
Send from the puppet-product-updates@puppet.com email alias to the following external aliases: <puppet-announce@googlegroups.com>, <puppet-dev@googlegroups.com>, <puppet-users@googlegroups.com>, <voxpupuli@groups.io>.


### Instructions on email content
Before sending, do check that all links are still valid. Feel free to adjust the text to match better with the circumstances of the release, or add other news that are relevant at the time. If you make changes, consider committing them here, for the benefit of future-you.

The github rendering of the markdown seems to copy&paste acceptably into Google Inbox.

The [CHANGELOG](https://github.com/puppetlabs/puppet-resource_api/blob/master/CHANGELOG.md) is a good starting point for finding enhancements and bug-fixes.

See [this post](https://groups.google.com/d/msg/puppet-dev/1R9gwkEIxHU/adWXJ0NfCAAJ) for an example.

---

Subject: [ANN] Resource API X.Y.Z Release

Hi all,

We're pleased to announce that version X.Y.Z of the Resource API is being released today.

The Resource API provides a simple way to create new native resources in the form of types and providers for Puppet. Using a little bit of ruby, you can finally get rid of that brittle exec, or manage that one API that eluded you until now.

It is provided as a Ruby gem to be referenced within modules. Support for it has been included as an experimental feature in the Puppet Development Kit (see `pdk new provider --help`). Use the [Puppet 6 packages](https://puppet.com/blog/introducing-puppet-6) or the [resource_api module](https://forge.puppet.com/puppetlabs/resource_api) to deploy it in your infrastructure. Note that if you are using Puppet 6 packages, you will have to wait until the next release to upgrade.

The new release of the Resource API provides the following enhancements:

* A
* B
* C

The new release also contains the following notable bugfixes:

* D
* E
* F

See the [CHANGELOG](https://github.com/puppetlabs/puppet-resource_api/blob/master/CHANGELOG.md) for a full list of changes.

We encourage all module developers to review the Resource API and use it when creating types and providers. The [README](https://github.com/puppetlabs/puppet-resource_api/blob/master/README.md) gets you going quickly. To see some example code see [this simple Philips Hue type](https://github.com/da-ar/hue_rsapi) or [the Palo Alto firewall module](https://github.com/puppetlabs/puppetlabs-panos).

Please let us know of your experiences with the Resource API, either here, on [Slack](https://slack.puppet.com/) (#forge-modules), or on the [github repo](https://github.com/puppetlabs/puppet-resource_api).


Thanks,
YOUR NAME
