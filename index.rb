# frozen_string_literal: true

require 'sinatra/base'
require 'pry'
require 'dalli'
require_relative 'daylight_hours'

# entry point for app
class DaylightApp < Sinatra::Application
  set :port, 3000
  enable :logging, :sessions
  set :dc, Dalli::Client.new('localhost:11211')
  attr_reader :nb_hash

  helpers do
    def json_params
      JSON.parse(request.body.read)
    rescue JSONError
      halt 400, { message: 'Invalid JSON' }.to_json
    end

    def extract_details_from_hash(hash)
      neighbourhood = hash['neighbourhood']
      building = hash['building']
      apartment = hash['apartment_number'].to_i - 1
      [neighbourhood, building, apartment]
    end
  end

  def set_cache(key, value)
    settings.dc.set(key, value)
    value
  end

  get '/init' do
    parameters = json_params['neighbourhoods']
    error = DaylightHours.validate_apartment_height(parameters)
    halt 400, { message: error }.to_json if error
    result = DaylightHours.prep_array(parameters)
    hash = result[:hash]
    array = result[:array]

    set_cache(:nb_array, array)
    set_cache(:nb_hash, hash)
  end

  get '/daylight_hours' do
    cache_handler = settings.dc
    @nb_hash = JSON.parse(cache_handler.get(:nb_hash))
    neighbourhood, building, apartment =
      extract_details_from_hash(json_params)
    find_building(neighbourhood, building)
    building_index = @nb_hash[neighbourhood]['buildings'][building]
    nb_index = @nb_hash[neighbourhood]['index']
    last = @nb_hash[neighbourhood]['buildings'].length - 1

    higher_left, higher_right =
      higher_to_sides(cache_handler, building_index, apartment, nb_index)

    get_hours(apartment, building_index, last, higher_left, higher_right)
  end

  private

  def higher_to_sides(cache_handler, building_index, apartment, nb_index)
    higher_left = DaylightHours.higher_to_left?(
      cache_handler, building_index, apartment, nb_index
    )
    higher_right = DaylightHours.higher_to_right?(
      cache_handler, building_index, apartment, nb_index
    )
    [higher_left, higher_right]
  end

  def get_hours(apartment, building_index, last, higher_left, higher_right)
    east_hours = west_hours = []
    if higher_left
      east_hours = DaylightHours
                   .add_hours_left(apartment, building_index)
    end
    if higher_right
      west_hours = DaylightHours
                   .add_hours_right(apartment, building_index, last)
    end

    DaylightHours.compute_total_hours(east_hours, west_hours)
  end

  def find_building(neighbourhood, building)
    if @nb_hash[neighbourhood].nil?
      halt 400, { message: 'Neighbourhood not found' }.to_json
    end
    return unless @nb_hash[neighbourhood]['buildings'][building].nil?

    halt 400, { message: 'Building not found' }.to_json
  end
end
