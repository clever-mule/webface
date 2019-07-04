# frozen_string_literal: true

require 'csv'

require 'bundler/setup'
Bundler.require(:default, :development)

DATASET_ATTRIBUTION = 'https://data.deutschebahn.com/dataset/data-stationsdaten'
DATASET_PATH = File.join(File.dirname(__FILE__),
                         '..',
                         'DBSuS-Uebersicht_Bahnhoefe-Stand2019-03.csv')
REPORT_TYPES = {
  count_by_bundesland_category: 'Number of stations per Bundesland and category',
}.freeze

class DataReader
  def sample
    csv_base.take(100)
  end

  def all_bundeslands
    csv_base.map { |e| e['Bundesland'] }.sort.uniq
  end

  private

  def csv_base
    CSV.foreach(DATASET_PATH, col_sep: ';', headers: true)
  end
end

class WebfaceApp < Sinatra::Application
  set :public_folder, File.join(File.dirname(__FILE__), 'static')

  before do
    @data_reader = DataReader.new
  end

  get '/' do
    @title = 'Dataset'
    @data = @data_reader.sample
    slim :home
  end

  get '/send_report' do
    @title = 'Send Report'
    slim :send_report
  end

  post '/send_report' do
    ap params
    redirect '/'
  end
end
