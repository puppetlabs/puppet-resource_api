# frozen_string_literal: true

# Whole new package, so include pack stuff
require_relative '../../../puppet/provider/package'

Puppet::Type.type(:package).provide :portupgrade, :parent => Puppet::Provider::Package do
  include Puppet::Util::Execution

  desc "Support for FreeBSD's ports using the portupgrade ports management software.
    Use the port's full origin as the resource name. eg (ports-mgmt/portupgrade)
    for the portupgrade port."

  ## has_features is usually autodetected based on defs below.
  # has_features :installable, :uninstallable, :upgradeable

  commands :portupgrade => "/usr/local/sbin/portupgrade",
           :portinstall => "/usr/local/sbin/portinstall",
           :portversion => "/usr/local/sbin/portversion",
           :portuninstall => "/usr/local/sbin/pkg_deinstall",
           :portinfo => "/usr/sbin/pkg_info"

  ## Activate this only once approved by someone important.
  # defaultfor 'os.name' => :freebsd

  # Remove unwanted environment variables.
  %w[INTERACTIVE UNAME].each do |var|
    if ENV.include?(var)
      ENV.delete(var)
    end
  end

  ######## instances sub command (builds the installed packages list)

  def self.instances
    Puppet.debug "portupgrade.rb Building packages list from installed ports"

    # regex to match output from pkg_info
    regex = /^(\S+)-([^-\s]+):(\S+)$/
    # Corresponding field names
    fields = [:portname, :ensure, :portorigin]
    # define Temporary hash used, packages array of hashes
    hash = Hash.new
    packages = []

    # exec command
    cmdline = ["-aoQ"]
    begin
      output = portinfo(*cmdline)
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error.new(output, e)
    end

    # split output and match it and populate temp hash
    output.split("\n").each { |data|
      # reset hash to nil for each line
      hash.clear
      match = regex.match(data)
      if match
        # Output matched regex
        fields.zip(match.captures) { |field, value|
          hash[field] = value
        }

        # populate the actual :name field from the :portorigin
        # Set :provider to this object name
        hash[:name] = hash[:portorigin]
        hash[:provider] = name

        # Add to the full packages listing
        packages << new(hash)
      else
        # unrecognised output from pkg_info
        Puppet.debug "portupgrade.Instances() - unable to match output: #{data}"
      end
    }

    # return the packages array of hashes
    packages
  end

  ######## Installation sub command

  def install
    Puppet.debug "portupgrade.install() - Installation call on #{@resource[:name]}"
    # -M: yes, we're a batch, so don't ask any questions
    cmdline = ["-M BATCH=yes", @resource[:name]]

    # FIXME: it's possible that portinstall prompts for data so locks up.
    begin
      output = portinstall(*cmdline)
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error.new(output, e)
    end

    if output =~ /\*\* No such /
      raise Puppet::ExecutionFailure, _("Could not find package %{name}") % { name: @resource[:name] }
    end

    # No return code required, so do nil to be clean
    nil
  end

  ######## Latest subcommand (returns the latest version available, or current version if installed is latest)

  def latest
    Puppet.debug "portupgrade.latest() - Latest check called on #{@resource[:name]}"
    # search for latest version available, or return current version.
    # cmdline = "portversion -v <portorigin>", returns "<portname> <code> <stuff>"
    # or "** No matching package found: <portname>"
    cmdline = ["-v", @resource[:name]]

    begin
      output = portversion(*cmdline)
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error.new(output, e)
    end

    # Check: output format.
    if output =~ /^\S+-([^-\s]+)\s+(\S)\s+(.*)/
      installedversion = Regexp.last_match(1)
      comparison = Regexp.last_match(2)
      otherdata = Regexp.last_match(3)

      # Only return a new version number when it's clear that there is a new version
      # all others return the current version so no unexpected 'upgrades' occur.
      case comparison
      when "=", ">"
        Puppet.debug "portupgrade.latest() - Installed package is latest (#{installedversion})"
        installedversion
      when "<"
        # "portpkg-1.7_5 < needs updating (port has 1.14)"
        # "portpkg-1.7_5 < needs updating (port has 1.14) (=> 'newport/pkg')
        if otherdata =~ /\(port has (\S+)\)/
          newversion = Regexp.last_match(1)
          Puppet.debug "portupgrade.latest() - Installed version needs updating to (#{newversion})"
          newversion
        else
          Puppet.debug "portupgrade.latest() - Unable to determine new version from (#{otherdata})"
          installedversion
        end
      when "?", "!", "#"
        Puppet.debug "portupgrade.latest() - Comparison Error reported from portversion (#{output})"
        installedversion
      else
        Puppet.debug "portupgrade.latest() - Unknown code from portversion output (#{output})"
        installedversion
      end

    elsif output =~ /^\*\* No matching package /
      # error: output not parsed correctly, error out with nil.
      # Seriously - this section should never be called in a perfect world.
      # as verification that the port is installed has already happened in query.
      raise Puppet::ExecutionFailure, _("Could not find package %{name}") % { name: @resource[:name] }
    else
      # Any other error (dump output to log)
      raise Puppet::ExecutionFailure, _("Unexpected output from portversion: %{output}") % { output: output }
    end
  end

  ###### Query subcommand - return a hash of details if exists, or nil if it doesn't.
  # Used to make sure the package is installed

  def query
    Puppet.debug "portupgrade.query() - Called on #{@resource[:name]}"

    cmdline = ["-qO", @resource[:name]]
    begin
      output = portinfo(*cmdline)
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error.new(output, e)
    end

    # Check: if output isn't in the right format, return nil
    if output =~ /^(\S+)-([^-\s]+)/
      # Fill in the details
      hash = Hash.new
      hash[:portorigin] = name
      hash[:portname]   = Regexp.last_match(1)
      hash[:ensure]     = Regexp.last_match(2)

      # If more details are required, then we can do another pkg_info
      # query here and parse out that output and add to the hash
      # return the hash to the caller
      hash
    else
      Puppet.debug "portupgrade.query() - package (#{@resource[:name]}) not installed"
      nil
    end
  end

  ####### Uninstall command

  def uninstall
    Puppet.debug "portupgrade.uninstall() - called on #{@resource[:name]}"
    # Get full package name from port origin to uninstall with
    cmdline = ["-qO", @resource[:name]]
    begin
      output = portinfo(*cmdline)
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error.new(output, e)
    end

    if output =~ /^(\S+)/
      # output matches, so uninstall it
      portuninstall Regexp.last_match(1)
    end
  end

  ######## Update/upgrade command

  def update
    Puppet.debug "portupgrade.update() - called on (#{@resource[:name]})"

    cmdline = ["-qO", @resource[:name]]
    begin
      output = portinfo(*cmdline)
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error.new(output, e)
    end

    if output =~ /^(\S+)/
      # output matches, so upgrade the software
      cmdline = ["-M BATCH=yes", Regexp.last_match(1)]
      begin
        output = portupgrade(*cmdline)
      rescue Puppet::ExecutionFailure => e
        raise Puppet::Error.new(output, e)
      end
    end
  end

  ## EOF
end
