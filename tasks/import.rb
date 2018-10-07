require 'csv'
require 'date'

def parse_date(date)
  return if date.nil? || date.empty?
  Date.parse(date)
end

desc 'import'
task :import do
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

  Sequel.connect(DB_URI) do |db_conn|
    projects.each_with_index do |project, i|
      print "\rProjects: #{i + 1}/#{projects.length}"
      db_conn[:projects] << project
    end
    puts
    organizations.each_with_index do |org, i|
      print "\rOrganizations: #{i + 1}/#{organizations.length}"
      db_conn[:organizations] << org
    end
    puts
    orgs_projects.each_with_index do |op, i|
      print "\rParticipations: #{i + 1}/#{orgs_projects.length}"
      db_conn[:participations] << op
    end
  end

  puts
end
