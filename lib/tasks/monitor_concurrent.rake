namespace :db do
  namespace :migrate do
    desc 'Run db:migrate but monitor ActiveRecord::ConcurrentMigrationError'
    task monitor_concurrent: :environment do
      total_sleep_duration = 0
      while total_sleep_duration <= 180
        begin
          Rake::Task['db:migrate'].reenable
          Rake::Task['db:migrate'].invoke
          break
        rescue ActiveRecord::ConcurrentMigrationError
          sleep_duration = rand(1..10)
          total_sleep_duration += sleep_duration
          puts "Migrations Sleeping #{sleep_duration} Seconds"
          sleep(sleep_duration)
        end
      end

      raise('Migrations failed to perform after 3 minutes') if total_sleep_duration > 180
    end
  end
end
