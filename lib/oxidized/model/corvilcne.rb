class CorvilCNE < Oxidized::Model

  prompt /\r[^\r]+\(config\)[\$#]\s?$/
  comment '! '

  def filter cfg
    cfg.gsub! prompt, ''
    cfg.gsub! /^(show\s.*)$/, '! \1'
    cfg
  end

  cmd :secret do |cfg|
     cfg.gsub! /^(.*radius-server\skey\s)"[^"]+"(.*)/, '\\1 <configuration removed> \\2'
     cfg.gsub! /^(.*radius-server\skey\s)\S+(.*)/, '\\1 <configuration removed> \\2'
     cfg.gsub! /^(.*tacacs-server\skey\s)"[^"]+"(.*)/, '\\1 <configuration removed> \\2'
     cfg.gsub! /^(.*tacacs-server\skey\s)\S+(.*)/, '\\1 <configuration removed> \\2'
     cfg.gsub! /^(.*community-string\s)"[^"]+"(.*)/, '\\1 <configuration removed> \\2'
     cfg.gsub! /^(.*community-string\s)\S+(.*)/, '\\1 <configuration removed> \\2'
     cfg
  end

  cmd 'show version' do |cfg|
    comment cfg
    filter cfg
  end

  cmd 'show config' do |cfg|
    filter cfg
  end

  cfg :ssh, :telnet do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end

  cfg :telnet do
    username /^[\w.@_()-]+\slogin:/
    password /^Password:/
  end
end
