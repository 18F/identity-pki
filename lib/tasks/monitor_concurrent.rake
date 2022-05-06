namespace :db do
  namespace :migrate do
    desc 'Run db:migrate but monitor ActiveRecord::ConcurrentMigrationError'
    task monitor_concurrent: :environment do
      loop do
        Rake::Task['db:migrate'].reenable
        Rake::Task['db:migrate'].invoke
        break
      rescue ActiveRecord::ConcurrentMigrationError
        sleep_duration = rand(1..10)
        puts "Migrations Sleeping #{sleep_duration} Seconds"
        sleep(sleep_duration)
      end
    end
  end
end
