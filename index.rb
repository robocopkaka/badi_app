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
    value
  end
  
  get '/init' do
    result = DaylightHours.prep_array(json_params["neighbourhoods"])
    hash = result[:hash]
    array = result[:hash]
    error = result[:error]
    halt 400, { message: error }.to_json if error
    set_cache(:nb_array, array)
    set_cache(:nb_hash, hash)
  end
  
  get '/daylight_hours' do
    cache_handler = settings.dc
    query = json_params
    neighbourhood = query["neighbourhood"]
    building = query["building"]
    apartment_number = query["apartment_number"].to_i
    hash = JSON.parse(cache_handler.get(:nb_hash))
    building_index = hash[neighbourhood]["buildings"][building]
    first = hash[neighbourhood]["start_index"]
    last = hash[neighbourhood]["end_index"]
    # binding.pry
    higher_to_left = DaylightHours
      .higher_to_left?(
        cache_handler, building_index, apartment_number - 1, first
      )
    higher_to_right = DaylightHours
      .higher_to_right?(
        cache_handler, building_index, apartment_number - 1, last
      )
    east_hours = west_hours = []
    east_hours = DaylightHours.add_hours_left(apartment_number - 1, building_index, first) if higher_to_left
    west_hours = DaylightHours.add_hours_right(apartment_number - 1, building_index, last) if higher_to_right
    
    DaylightHours.compute_total_hours(east_hours, west_hours)
  end
end