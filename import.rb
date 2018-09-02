require 'csv'
require 'date'

require 'bundler/setup'
Bundler.require(:default, :development)

DBFILE = 'cordis-h2020.db'.freeze

FileUtils.rm(DBFILE)
DB = Sequel.sqlite(DBFILE)

DB.create_table :projects do
  Bigint :rcn
  Bigint :id
  String :acronym, size: 127
  String :status, size: 127
  String :title, size: 2047
  Date :start_date
  Date :end_date

  primary_key [:rcn, :id]
end

DB.create_table :organizations do
  Bigint :id, primary_key: true
  Bigint :project_rcn
  Bigint :project_id
  String :role, size: 127
  String :name, text: true
  String :short_name, size: 255
  String :activity_type, size: 11
  String :country, size: 5

  foreign_key [:project_rcn, :project_id], :projects
end

def parse_date(date)
  return if date.nil? || date.empty?
  Date.parse(date)
end

puts "Reading projects\n"

projects = CSV.read('cordis-h2020projects.csv',
                    encoding: Encoding::ISO_8859_1,
                    col_sep: ';', headers: true)

projects.each_with_index do |row, i|
  print "\rReading project #{i + 1}/#{projects.size}"
  data = {
    rcn: row['rcn'].to_i,
    id: row['id'].to_i,
    acronym: row['acronym'],
    status: row['status']&.downcase,
    title: row['title'],
    start_date: parse_date(row['startDate']),
    end_date: parse_date(row['endDate'])
  }
  DB[:projects] << data
end

puts "\nReading organizations\n"

orgs = CSV.read('cordis-h2020organizations.csv',
                encoding: Encoding::ISO_8859_1,
                col_sep: ';', headers: true)

orgs.each_with_index do |row, i|
  print "\rReading org #{i + 1}/#{orgs.size}"
  data = {
    id: i + 1,
    project_rcn: row['projectRcn'].to_i,
    project_id: row['projectID'].to_i,
    role: row['role'],
    name: row['name']&.capitalize,
    short_name: row['shortName'],
    activity_type: row['activityType']&.gsub('/', ''),
    country: row['country']
  }
  DB[:organizations] << data
end
