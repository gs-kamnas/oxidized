require 'simplecov'
SimpleCov.start

if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'mock_redis'
require 'minitest/autorun'
require 'mocha/minitest'
require 'oxidized'

Oxidized.mgr = Oxidized::Manager.new

# Monkey patch redis_connect to use mock_redis
module Oxidized
  class Node
    class RedisStats
      def redis_connect(*)
        @redis = MockRedis.new
      end
    end
  end
end

def stub_oxidized_ssh(node)
  Oxidized::SSH.any_instance.stubs(:connect).returns(true)
  Oxidized::SSH.any_instance.stubs(:node).returns(node)
  Oxidized::SSH.any_instance.expects(:cmd).at_least(1).returns("this is a command output\nModel: mx960")
  Oxidized::SSH.any_instance.stubs(:connect_cli).returns(true)
  Oxidized::SSH.any_instance.stubs(:disconnect).returns(true)
  Oxidized::SSH.any_instance.stubs(:disconnect_cli).returns(true)
end

def stub_oxidized_ssh_fail(node)
  Oxidized::SSH.any_instance.stubs(:connect).returns(false)
  Oxidized::SSH.any_instance.stubs(:node).returns(node)
  Oxidized::SSH.any_instance.expects(:cmd).never
  Oxidized::SSH.any_instance.stubs(:connect_cli).returns(false)
  Oxidized::SSH.any_instance.stubs(:disconnect).returns(false)
  Oxidized::SSH.any_instance.stubs(:disconnect_cli).returns(false)
end
