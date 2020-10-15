require 'sinatra/base'
require 'pry'
require 'dalli'
require_relative 'daylight_hours'

class DaylightApp < Sinatra::Application
  set :port, 3000
  enable :logging, :sessions
  set :dc, Dalli::Client.new('localhost:11211')
  attr_accessor :app_instance
  
  helpers do
    def json_params
      JSON.parse(request.body.read)
    rescue
      halt 400, { message: "Invalid JSON" }.to_json
    end
  end

  def set_cache key, value
    settings.dc.set(key, value)
    return value
  end
  
  get '/init' do
    set_cache(:app_instance, DaylightHours.new(json_params["neighbourhoods"]))
  end
  
  get '/daylight_hours' do
    settings.dc.get(:app_instance)
  end
end