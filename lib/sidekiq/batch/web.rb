require 'sidekiq/web'

module Sidekiq
  class Batch
    module Web

      LOCALE_PATH = Pathname.new(__dir__).join('web/locales')
      VIEW_PATH = Pathname.new(__dir__).join('web/views')

      def self.registered(app)
        app.settings.locales.push(LOCALE_PATH)
        app.get '/batches' do
          redis = Sidekiq.redis { |r| r }

          @batches = redis.zrange('batches',0, -1)
          @batches.map! do |batch_id|
            normalized_id = batch_id.delete_prefix('BID-')
            Status.new(normalized_id)
          end

          erb VIEW_PATH.join('batches.erb').read
        end

        app.get '/batches/:id' do
          @batch = Status.new(params[:id])

          erb VIEW_PATH.join('batch.erb').read
        end

        app.get '/filter/retries' do
          @retries = Sidekiq::RetrySet.new.scan(params[:query])
          @current_page = 1
          @count = @total_size = @retries.size

          erb :retries
        end
      end

    end
  end
end

Sidekiq::Web.register(Sidekiq::Batch::Web)
Sidekiq::Web.tabs['Batches'] = 'batches'
