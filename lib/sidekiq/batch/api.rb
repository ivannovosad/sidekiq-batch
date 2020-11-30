require 'sidekiq/api'

module Sidekiq
  class JobSet

    def scan(match, count = 100)
      match_regexp = "*#{match}*"

      Sidekiq.redis do |redis|
        redis.zscan_each(name, match: match_regexp, count: count).map do |entry, score|
          SortedEntry.new(self, score, entry)
        end
      end
    end

  end
end
