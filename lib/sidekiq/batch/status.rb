module Sidekiq
  class Batch
    class Status
      attr_reader :bid

      def initialize(bid)
        @bid = bid
      end

      def join
        raise "Not supported"
      end

      def expires_at
        return unless created_at
        created_at + Sidekiq.redis { |r| r.ttl("BID-#{bid}") }.to_i
      end

      def pending
        Sidekiq.redis { |r| r.hget("BID-#{bid}", 'pending') }.to_i
      end

      def failures
        Sidekiq.redis { |r| r.scard("BID-#{bid}-failed") }.to_i
      end

      def created_at
        created_at = Sidekiq.redis { |r| r.hget("BID-#{bid}", 'created_at') }
        return unless created_at
        Time.at(created_at.to_f)
      end

      def description
        Sidekiq.redis { |r| r.hget("BID-#{bid}", 'description') }
      end

      def total
        Sidekiq.redis { |r| r.hget("BID-#{bid}", 'total') }.to_i
      end

      def parent_bid
        Sidekiq.redis { |r| r.hget("BID-#{bid}", "parent_bid") }
      end

      def failure_info
        Sidekiq.redis { |r| r.smembers("BID-#{bid}-failed") } || []
      end

      def complete?
        'true' == Sidekiq.redis { |r| r.hget("BID-#{bid}", 'complete') }
      end

      def child_count
        Sidekiq.redis { |r| r.hget("BID-#{bid}", 'children') }.to_i
      end

      def success_pct
        return 0 if total == 0
        ((total - pending) / Float(total)) * 100
      end

      def pending_pct
        return 0 if total == 0
        ((pending - failures) / Float(total)) * 100
      end

      def failure_pct
        return 0 if total == 0
        (failures / Float(total)) * 100
      end

      Failure = Struct.new(:jid, :error_class, :error_message)
      def failed_jobs
        failures = Sidekiq.redis {|conn| conn.hgetall("BID-#{bid}-failinfo") }
        failures.map {|jid, json| Failure.new(jid, *Sidekiq.load_json(json)) }
      end

      def data
        {
          bid: bid,
          total: total,
          failures: failures,
          pending: pending,
          created_at: created_at,
          complete: complete?,
          failure_info: failure_info,
          parent_bid: parent_bid,
          child_count: child_count
        }
      end
    end
  end
end
