require 'bundler/setup'
APP_ENV = ENV.fetch('APP_ENV', :development).to_sym
Bundler.require(:default, APP_ENV)

# settings

require_relative './config/_base'
require_relative "./config/#{APP_ENV}"
