require 'spec_helper'
require 'oxidized/input/ssh'

describe Oxidized::SSH do
  before(:each) do
    Oxidized.asetus = Asetus.new
    Oxidized.setup_logger
    Oxidized.config.timeout = 30
    Oxidized.config.input.ssh.secure = true
    Oxidized::Node.any_instance.stubs(:resolve_repo)
    Oxidized::Node.any_instance.stubs(:resolve_input)
    Oxidized::Node.any_instance.stubs(:resolve_output)
  end

  describe "#connect" do
    it "should use proxy command when proxy host given and connect by ip if resolve_dns is true" do
      Oxidized.config.resolve_dns = true
      @node = Oxidized::Node.new(name:     'localhost4.localdomain4',
                                 input:    'ssh',
                                 output:   'git',
                                 model:    'junos',
                                 username: 'alma',
                                 password: 'armud',
                                 vars:     { ssh_proxy: 'test.com' })

      ssh = Oxidized::SSH.new

      model = mock
      model.expects(:cfg).returns('ssh' => [])
      @node.expects(:model).returns(model).at_least_once

      proxy = mock
      Net::SSH::Proxy::Command.expects(:new).with("ssh test.com -W [%h]:%p").returns(proxy)
      Net::SSH.expects(:start).with('127.0.0.1', 'alma',  port:                             22,
                                                          verify_host_key:                  Oxidized.config.input.ssh.secure ? :always : :never,
                                                          append_all_supported_algorithms:  true,
                                                          forward_agent:                    false,
                                                          keepalive:                        true,
                                                          password:                         'armud',
                                                          timeout:                          Oxidized.config.timeout,
                                                          number_of_password_prompts:       0,
                                                          auth_methods:                     %w[none publickey password],
                                                          proxy:                            proxy)

      ssh.instance_variable_set("@exec", true)
      ssh.connect(@node)
    end

    it "should use proxy command when proxy host given and connect by name if resolve_dns is false" do
      Oxidized.config.resolve_dns = false
      @node = Oxidized::Node.new(name:     'localhost4.localdomain4',
                                 input:    'ssh',
                                 output:   'git',
                                 model:    'junos',
                                 username: 'alma',
                                 password: 'armud',
                                 vars:     { ssh_proxy: 'test.com' })

      ssh = Oxidized::SSH.new

      model = mock
      model.expects(:cfg).returns('ssh' => [])
      @node.expects(:model).returns(model).at_least_once

      proxy = mock
      Net::SSH::Proxy::Command.expects(:new).with("ssh test.com -W [%h]:%p").returns(proxy)
      Net::SSH.expects(:start).with('localhost4.localdomain4', 'alma',  port:                             22,
                                                            verify_host_key:                  Oxidized.config.input.ssh.secure ? :always : :never,
                                                            append_all_supported_algorithms:  true,
                                                            forward_agent:                    false,
                                                            keepalive:                        true,
                                                            password:                         'armud',
                                                            timeout:                          Oxidized.config.timeout,
                                                            number_of_password_prompts:       0,
                                                            auth_methods:                     %w[none publickey password],
                                                            proxy:                            proxy)

      ssh.instance_variable_set("@exec", true)
      ssh.connect(@node)
    end
  end
end
