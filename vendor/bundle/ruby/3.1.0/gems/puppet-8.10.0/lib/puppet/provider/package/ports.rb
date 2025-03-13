# frozen_string_literal: true

Puppet::Type.type(:package).provide :ports, :parent => :freebsd, :source => :freebsd do
  desc "Support for FreeBSD's ports.  Note that this, too, mixes packages and ports."

  commands :portupgrade => "/usr/local/sbin/portupgrade",
           :portversion => "/usr/local/sbin/portversion",
           :portuninstall => "/usr/local/sbin/pkg_deinstall",
           :portinfo => "/usr/sbin/pkg_info"

  %w[INTERACTIVE UNAME].each do |var|
    ENV.delete(var) if ENV.include?(var)
  end

  def install
    # -N: install if the package is missing, otherwise upgrade
    # -M: yes, we're a batch, so don't ask any questions
    cmd = %w[-N -M BATCH=yes] << @resource[:name]

    output = portupgrade(*cmd)
    if output =~ /\*\* No such /
      raise Puppet::ExecutionFailure, _("Could not find package %{name}") % { name: @resource[:name] }
    end
  end

  # If there are multiple packages, we only use the last one
  def latest
    cmd = ["-v", @resource[:name]]

    begin
      output = portversion(*cmd)
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error.new(output, e)
    end
    line = output.split("\n").pop

    unless line =~ /^(\S+)\s+(\S)\s+(.+)$/
      # There's no "latest" version, so just return a placeholder
      return :latest
    end

    pkgstuff = Regexp.last_match(1)
    match = Regexp.last_match(2)
    info = Regexp.last_match(3)

    unless pkgstuff =~ /^\S+-([^-\s]+)$/
      raise Puppet::Error,
            _("Could not match package info '%{pkgstuff}'") % { pkgstuff: pkgstuff }
    end

    version = Regexp.last_match(1)

    if match == "=" or match == ">"
      # we're up to date or more recent
      return version
    end

    # Else, we need to be updated; we need to pull out the new version

    unless info =~ /\((\w+) has (.+)\)/
      raise Puppet::Error,
            _("Could not match version info '%{info}'") % { info: info }
    end

    source = Regexp.last_match(1)
    newversion = Regexp.last_match(2)

    debug "Newer version in #{source}"
    newversion
  end

  def query
    # support portorigin_glob such as "mail/postfix"
    name = self.name
    if name =~ %r{/}
      name = self.name.split(%r{/}).slice(1)
    end
    self.class.instances.each do |instance|
      if instance.name == name
        return instance.properties
      end
    end

    nil
  end

  def uninstall
    portuninstall @resource[:name]
  end

  def update
    install
  end
end
