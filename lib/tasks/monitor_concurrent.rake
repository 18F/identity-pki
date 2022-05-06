namespace :db do
  namespace :migrate do
    desc 'Run db:migrate but monitor ActiveRecord::ConcurrentMigrationError'
    task monitor_concurrent: :environment do
      attempts = 0
      while attempts <= 15
        begin
          attempts += 1
          Rake::Task['db:migrate'].reenable
          Rake::Task['db:migrate'].invoke
          break
        rescue ActiveRecord::ConcurrentMigrationError
          sleep_duration = rand(1..10)
          puts "Migrations Sleeping #{sleep_duration} Seconds"
          sleep(sleep_duration)
        end
      end

      raise('Migrations failed to perform after 15 attempts') if attempts > 15
    end
  end
end
