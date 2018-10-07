require_relative './_loader'

Dir['./tasks/*.rb'].each { |f| require_relative f }

namespace :db do
  desc 'Migrate the database'
  task :migrate do
    version = ENV['VERSION'].to_i if ENV['VERSION']
    Sequel.connect(DB_URI) do |db|
      Sequel::Migrator.run(db, './migrations/', target: version)
    end
  end
end
