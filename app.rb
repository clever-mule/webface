# frozen_string_literal: true

require 'csv'

require 'bundler/setup'
Bundler.require(:default, :development)

DATASET_ATTRIBUTION = 'https://data.deutschebahn.com/dataset/data-stationsdaten'
DATASET_PATH = File.join(File.dirname(File.absolute_path(__FILE__)),
                         '..',
                         'DBSuS-Uebersicht_Bahnhoefe-Stand2019-03.csv')

module DataReader
  def self.call
    CSV.foreach(DATASET_PATH, col_sep: ';', headers: true).take(100)
  end
end

class WebfaceApp < Sinatra::Application
  get '/' do
    @title = 'Dataset'
    @data = DataReader.call
    slim :home
  end
end
