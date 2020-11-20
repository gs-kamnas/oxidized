class ExalinkFusion < Oxidized::Model
  # Exablaze Fusion #
  prompt /^\S+@\S+>\s$/
  comment  ''

  cmd :all do |cfg|
     lines = cfg.each_line.to_a[1..-2]
     (lines << "-" * 80 << "\n" * 2).join
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp\s\S+\scommunity).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(snmp\strap\starget\s\S+).*/, '\\1 <configuration removed>'
    cfg
  end

  cmd 'show version' do |cfg|
    cfg
  end

  cmd 'show power-supply' do |cfg|
    cfg.gsub! /^Input\s+:.*\r?\n/, ''
    cfg.gsub! /^Output\s+:.*\r?\n/, ''
    cfg.gsub! /^Temperature\s+:.*\r?\n/, ''
    cfg
  end

  cmd 'show running-config' do |cfg|
    cfg
  end

  cfg :ssh, :telnet do
    pre_logout 'exit'
  end

  cfg :telnet do
    username /^\S+\slogin:/
    password /^Password:/
  end
end
