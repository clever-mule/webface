# frozen_string_literal: true

require 'csv'
require 'forwardable'

require 'bundler/setup'
Bundler.require(:default, :development)

DATASET_ATTRIBUTION = 'https://data.deutschebahn.com/dataset/data-stationsdaten'
DATASET_PATH = File.join(File.dirname(__FILE__),
                         '..',
                         'DBSuS-Uebersicht_Bahnhoefe-Stand2019-03.csv')
REPORT_TYPES = {
  count_by_bundesland_category: 'Number of stations per Bundesland and category',
  count_by_bundesland_sp: 'Number of stations per Bundesland and service provider'
}.freeze

EXCHANGE_NAME = 'clever-mule:webface-entry'
QUEUE_NAME = 'clever-mule:report-tasks'

class DataReader
  def sample
    csv_base.take(100)
  end

  def all_bundeslands
    all_categories 'Bundesland'
  end

  def all_service_providers
    all_categories 'Aufgabenträger'
  end

  private

  def all_categories(name)
    csv_base.map { |e| e[name] }.sort.uniq
  end

  def csv_base
    CSV.foreach(DATASET_PATH, col_sep: ';', headers: true)
  end
end

class BunnySender
  attr_reader :connection, :channel, :exchange, :queue
  extend Forwardable

  def_delegator :@exchange, :publish

  def initialize
    @connection = Bunny.new
  end

  def start!
    @connection.start

    @channel = @connection.create_channel
    @exchange = @channel.direct(EXCHANGE_NAME)
    @queue = @channel.queue(QUEUE_NAME)
    @queue.bind(EXCHANGE_NAME)

    self
  end

  def stop!
    @connection.close
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
    @bunny_sender = BunnySender.new
    @bunny_sender.start!
    @bunny_sender.publish(params[:data].to_h.to_json,
                          content_type: 'application/json',
                          headers: { 'X-Report-Type' => params[:report_type] })
    redirect '/'
  end
end
