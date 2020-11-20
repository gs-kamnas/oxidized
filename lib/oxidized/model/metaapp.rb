class MetaApp < Oxidized::Model
  # MetaMako MetaApp #
  prompt /^\S+[#>]?$/
  comment  '! '

  cmd :all do |cfg|
     lines = cfg.each_line.to_a[1..-2]
     (lines << "-" * 80 << "\n" * 2).join
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp\s\S+\scommunity).*/, '\\1 <configuration removed>'
    cfg.gsub! /^(snmp\strap\starget\s\S+).*/, '\\1 <configuration removed>'
    cfg.gsub! /username (\S+) secret sha512 (\S+).*/, '<secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    cfg.gsub! /^Uptime.*/, '\\1 '
    cfg
  end

  cmd 'show running-config' do |cfg|
    cfg.gsub! /time.*/, '\\1 '
    cfg
  end

  cmd 'show inventory' do |cfg|
    cfg.gsub! /Local Time.*/, '\\1 '
    cfg
  end

  cmd 'show fpga' do |cfg|
    cfg
  end

  cmd 'show matrix' do |cfg|
    cfg
  end

  cfg :ssh, :telnet do
    if vars :enable
      post_login do
        send "enable\n"
        # Interpret enable: true as meaning we won't be prompted for a password
        unless vars(:enable).is_a? TrueClass
          expect /[pP]assword:\s?$/
          send vars(:enable) + "\n"
        end
        expect /^\S+[#>]?$/
      end
      post_login 'terminal length 0'
    end
    pre_logout 'exit'
  end

  cfg :telnet do
    username /^\S+\slogin:/
    password /^Password:/
  end
end
