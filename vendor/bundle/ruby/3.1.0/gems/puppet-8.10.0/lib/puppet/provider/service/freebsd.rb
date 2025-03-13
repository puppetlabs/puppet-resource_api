# frozen_string_literal: true

Puppet::Type.type(:service).provide :freebsd, :parent => :init do
  desc "Provider for FreeBSD and DragonFly BSD. Uses the `rcvar` argument of init scripts and parses/edits rc files."

  confine 'os.name' => [:freebsd, :dragonfly]
  defaultfor 'os.name' => [:freebsd, :dragonfly]

  def rcconf()        '/etc/rc.conf' end
  def rcconf_local()  '/etc/rc.conf.local' end
  def rcconf_dir()    '/etc/rc.conf.d' end

  def self.defpath
    superclass.defpath
  end

  def error(msg)
    raise Puppet::Error, msg
  end

  # Executing an init script with the 'rcvar' argument returns
  # the service name, rcvar name and whether it's enabled/disabled
  def rcvar
    rcvar = execute([initscript, :rcvar], :failonfail => true, :combine => false, :squelch => false)
    rcvar = rcvar.split("\n")
    rcvar.delete_if { |str| str =~ /^#\s*$/ }
    rcvar[1] = rcvar[1].gsub(/^\$/, '')
    rcvar
  end

  # Extract value name from service or rcvar
  def extract_value_name(name, rc_index, regex, regex_index)
    value_name = rcvar[rc_index]
    error("No #{name} name found in rcvar") if value_name.nil?
    value_name = value_name.gsub!(regex, regex_index)
    error("#{name} name is empty") if value_name.nil?
    debug("#{name} name is #{value_name}")
    value_name
  end

  # Extract service name
  def service_name
    extract_value_name('service', 0, /# (\S+).*/, '\1')
  end

  # Extract rcvar name
  def rcvar_name
    extract_value_name('rcvar', 1, /(.*?)(_enable)?=(.*)/, '\1')
  end

  # Extract rcvar value
  def rcvar_value
    value = rcvar[1]
    error("No rcvar value found in rcvar") if value.nil?
    value = value.gsub!(/(.*)(_enable)?="?(\w+)"?/, '\3')
    error("rcvar value is empty") if value.nil?
    debug("rcvar value is #{value}")
    value
  end

  # Edit rc files and set the service to yes/no
  def rc_edit(yesno)
    service = service_name
    rcvar = rcvar_name
    debug("Editing rc files: setting #{rcvar} to #{yesno} for #{service}")
    rc_add(service, rcvar, yesno) unless rc_replace(service, rcvar, yesno)
  end

  # Try to find an existing setting in the rc files
  # and replace the value
  def rc_replace(service, rcvar, yesno)
    success = false
    # Replace in all files, not just in the first found with a match
    [rcconf, rcconf_local, rcconf_dir + "/#{service}"].each do |filename|
      next unless Puppet::FileSystem.exist?(filename)

      s = File.read(filename)
      next unless s.gsub!(/^(#{rcvar}(_enable)?)="?(YES|NO)"?/, "\\1=\"#{yesno}\"")

      Puppet::FileSystem.replace_file(filename) { |f| f << s }
      debug("Replaced in #{filename}")
      success = true
    end
    success
  end

  # Add a new setting to the rc files
  def rc_add(service, rcvar, yesno)
    append = "\# Added by Puppet\n#{rcvar}_enable=\"#{yesno}\"\n"
    # First, try the one-file-per-service style
    if Puppet::FileSystem.exist?(rcconf_dir)
      File.open(rcconf_dir + "/#{service}", File::WRONLY | File::APPEND | File::CREAT, 0o644) { |f|
        f << append
        debug("Appended to #{f.path}")
      }
    elsif Puppet::FileSystem.exist?(rcconf_local)
      # Else, check the local rc file first, but don't create it
      File.open(rcconf_local, File::WRONLY | File::APPEND) { |f|
        f << append
        debug("Appended to #{f.path}")
      }
    else
      # At last use the standard rc.conf file
      File.open(rcconf, File::WRONLY | File::APPEND | File::CREAT, 0o644) { |f|
        f << append
        debug("Appended to #{f.path}")
      }
    end
  end

  def enabled?
    if /YES$/ =~ rcvar_value
      debug("Is enabled")
      return :true
    end
    debug("Is disabled")
    :false
  end

  def enable
    debug("Enabling")
    rc_edit("YES")
  end

  def disable
    debug("Disabling")
    rc_edit("NO")
  end

  def startcmd
    [initscript, :onestart]
  end

  def stopcmd
    [initscript, :onestop]
  end

  def statuscmd
    [initscript, :onestatus]
  end
end
