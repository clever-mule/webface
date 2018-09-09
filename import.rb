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
  String :name, text: true
  String :short_name, size: 255
  String :activity_type, size: 11
  String :country, size: 5

end

DB.create_table :participations do
  Bigint :project_rcn
  Bigint :project_id
  String :role, size: 127

  foreign_key :organization_id, :organizations
  foreign_key [:project_rcn, :project_id], :projects
end

def parse_date(date)
  return if date.nil? || date.empty?
  Date.parse(date)
end

CSV_SETTINGS = { encoding: Encoding::ISO_8859_1, col_sep: ';', headers: true }.freeze

projects_file = open('cordis-h2020projects.csv')
orgs_file = open('cordis-h2020organizations.csv')

puts "Reading projects"

projects = CSV.foreach(projects_file, **CSV_SETTINGS).map do |row|
  {
    rcn: row['rcn'].to_i,
    id: row['id'].to_i,
    acronym: row['acronym'],
    status: row['status']&.downcase,
    title: row['title'],
    start_date: parse_date(row['startDate']),
    end_date: parse_date(row['endDate'])
  }
end

puts "Reading organizations"

def make_org(row)
  {
    name: row['name']&.capitalize,
    short_name: row['shortName'],
    activity_type: row['activityType']&.gsub('/', ''),
    country: row['country']
  }
end

organizations = CSV.foreach(orgs_file, **CSV_SETTINGS)
                   .reject { |row| row['name'].nil? }
                   .map { |row| make_org(row) }
organizations.uniq! { |org| org[:name] }
organizations.each_with_index { |data, i| data[:id] = i + 1 }
orgs_index = organizations.map { |org| [org[:name], org] }.to_h

def make_participation(row, orgs_index)
  {
    organization_id: orgs_index[row['name'].capitalize][:id],
    project_rcn: row['projectRcn'].to_i,
    project_id: row['projectID'].to_i,
    role: row['role']
  }
end

puts 'Reading participations'

orgs_projects = CSV.foreach(orgs_file.tap(&:rewind), **CSV_SETTINGS)
                   .reject { |row| row['name'].nil? }
                   .map { |row| make_participation(row, orgs_index) }

puts "Writing the database\n"

projects.each_with_index do |project, i|
  print "\rProjects: #{i + 1}/#{projects.length}"
  DB[:projects] << project
end
puts
organizations.each_with_index do |org, i|
  print "\rOrganizations: #{i + 1}/#{organizations.length}"
  DB[:organizations] << org
end
puts
orgs_projects.each_with_index do |op, i|
  print "\rParticipations: #{i + 1}/#{orgs_projects.length}"
  DB[:participations] << op
end
puts
