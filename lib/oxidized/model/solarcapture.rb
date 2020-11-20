class SolarCapture < Oxidized::Model

  comment '# '
  prompt /^(\[[^\]]#\s?)$/

  def encapsulate(heading, lines)
    "# #{heading}:\n\n#{lines}\n"
  end

  cmd :secret do |cfg|
    cfg.gsub! /^([\s#]*community:\s*)['"].*/, '\\1 <configuration removed>'
    cfg.gsub! /^([\s#]*privacyPassword:\s*)['"].*/, '\\1 <configuration removed>'
    cfg.gsub! /^([\s#]*authPassword:\s*)['"].*/, '\\1 <configuration removed>'
    cfg
  end

  cmd("cat /etc/passwd") { |cfg| encapsulate("/etc/passwd", cfg) }
  cmd("cat /etc/group") { |cfg| encapsulate("/etc/group", cfg) }
  cmd("cat /etc/solarsystem/capture_roles.cfg") { |cfg| encapsulate("/etc/solarsystem/capture_roles.cfg", cfg) }
  cmd("cat /etc/solarsystem/capture_system.cfg") { |cfg| encapsulate("/etc/solarsystem/capture_system.cfg", cfg) }
  cmd("cat /etc/solarsystem/capture_postgres.conf") { |cfg| encapsulate("/etc/solarsystem/capture_postgres.conf", cfg) }
  cmd("/usr/bin/sudo -n /usr/sbin/sfcap_configure -i --stdout-only") { |cfg| encapsulate("sfcap_configure -i", cfg) }
  cmd("/usr/bin/sudo -n /usr/sbin/sfcap_configure -p current --stdout-only") { |cfg| encapsulate("sfcap_configure -p current", cfg) }

  cfg :ssh do
    exec true # don't run shell, run each command in exec channel
  end
end
