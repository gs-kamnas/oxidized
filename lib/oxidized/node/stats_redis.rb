module Oxidized
  require_relative 'stats'
  class Node
    class RedisStats < NodeStats
      attr_reader :mtimes
      MAX_STAT = 10
      RECONNECT_ATTEMPTS = 10

      # @param [Job] job job whose information add to stats
      # @return [void]
      def add(job)
        stat = {
          start: job.start,
          end:   job.end,
          time:  job.time
        }

        # Write the new stat and purge old stats atomically
        stat_keyname = "#{@stat_prefix}.#{job.status}"
        counter_keyname = "#{@counter_prefix}.#{job.status}"
        @redis.multi do
          @redis.rpush(stat_keyname, stat.to_json)
          @redis.ltrim(stat_keyname, (-1*@history_size), -1)
          @redis.incr(counter_keyname)
        end
      end

      # @param [Symbol] status stats for specific status
      # @return [Hash,Array] Hash of stats for every status or Array of stats for specific status
      def get(status = nil)
        return get_status_single status unless status.nil?

        stats = {}
        ALL_STATUSES.each { |stat| stats[stat] = get_status_single(stat) }
        stats
      end

      def get_counter(counter = nil)
        return get_counter_single counter unless counter.nil?

        counters = {}
        ALL_STATUSES.each { |stat| counters[stat] = get_counter_single(stat) }
        counters
      end

      def successes
        get_counter(:success)
      end

      def failures
        failures = 0
        ALL_STATUSES.each { |stat| failures += get_counter(stat) unless stat == :success }
        failures
      end

      def mtime
        @redis.lindex(@mtime_prefix, 0) || "unknown"
      end

      def update_mtime
        @redis.multi do
          @redis.lpush(@mtime_prefix, Time.now.utc)
          @redis.ltrim(@mtime_prefix, 0, (@history_size - 1))
        end
      end

      private

      def initialize(opt)
        @name = opt[:name]
        @history_size = Oxidized.config.stats.history_size? || MAX_STAT
        @reconnect_attempts = Oxidized.config.stats.redis_reconnect_attempts? || RECONNECT_ATTEMPTS
        @stat_prefix = "#{@name}.stats"
        @counter_prefix = "#{@name}.counter"
        @mtime_prefix = "#{@name}.mtimes"
        redis_connect(Oxidized.config.stats.redis_url)
      end

      def redis_connect(url)
        begin
          # Idempotent
          require "redis"
        rescue LoadError
          raise OxidizedError, 'redis gem not found: gem install redis - \
          or disable redis state storage support by setting "redis_url: false"\
          in the stats: section of your configuration.'
        end
        @redis = Redis.new(url: url, reconnect_attempts: @reconnect_attempts, reconnect_delay: 1.5, reconnect_delay_max: 10.0)
      end

      def get_status_single(status)
        stat_keyname = "#{@stat_prefix}.#{status}"
        js_stats = @redis.lrange(stat_keyname, 0, -1)
        stats = js_stats.map { |s| JSON.parse(s, symbolize_names: true) }
        return nil if stats.empty?

        stats
      end

      def get_counter_single(status)
        ctr_keyname = "#{@counter_prefix}.#{status}"
        @redis.get(ctr_keyname).to_i
      end
    end
  end
end
