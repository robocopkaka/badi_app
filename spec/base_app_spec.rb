# frozen_string_literal: true

ENV['APP_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require 'dalli'
require_relative '../base_app'

RSpec.describe 'base app spec' do
  include Rack::Test::Methods
  let(:params) do
    {
      'neighbourhoods' => [
        {
          'neighbourhood' => 'miami',
          'apartments_height' => 18,
          'buildings' => [
            {
              'name' => 'O1',
              'apartments_count' => 5,
              'distance' => 1
            },
            {
              'name' => 'O2',
              'apartments_count' => 3,
              'distance' => 1
            },
            {
              'name' => 'O3',
              'apartments_count' => 7,
              'distance' => 1
            }
          ]
        },
        {
          'neighbourhood' => 'new york',
          'apartments_height' => 18,
          'buildings' => [
            {
              'name' => 'ny_1',
              'apartments_count' => 5,
              'distance' => 1
            },
            {
              'name' => 'ny_2',
              'apartments_count' => 3,
              'distance' => 1
            },
            {
              'name' => 'ny_3',
              'apartments_count' => 7,
              'distance' => 1
            }
          ]
        }
      ]
    }
  end

  def app
    BaseApp
  end

  describe '/init' do
    after do
      cache_handler.delete(:nb_array)
      cache_handler.delete(:nb_hash)
    end
    context 'when init is called with valid json' do
      it 'returns a hash that maps to each building' do
        post '/init', params.to_json
        response = JSON.parse(last_response.body)
        expect(response.keys).to include 'miami'
        expect(response.keys).to include 'new york'
      end
    end

    context 'when init is called with invalid parameters' do
      it 'returns an error' do
        post '/init', params
        response = JSON.parse(last_response.body)
        expect(response['message']).to eq 'Invalid JSON'
      end
    end

    context 'when an building has more than 18 floors' do
      it 'returns an error message' do
        params['neighbourhoods']
          .first['buildings'].first['apartments_count'] = 20
        post '/init', params.to_json
        response = JSON.parse(last_response.body)
        expect(response['message'])
          .to include 'number of apartments allowed for a building is 18'
      end
    end
  end

  describe '/getSunlightHours' do
    before do
      post '/init', params.to_json
    end
    after do
      cache_handler.delete(:nb_array)
      cache_handler.delete(:nb_hash)
    end
    let(:query) do
      { neighbourhood: 'miami', building: 'O1', apartment_number: 1 }
    end
    context 'when a valid neighbourhood and building name is passed' do
      it 'returns daylight hours for the apartment passed' do
        get '/getSunlightHours', query
        expect(last_response).to be_ok
        expect(last_response.body).to include '08:14:00'
      end
    end

    context 'when an apartment is at the east-most part' do
      it 'starts receiving sunlight at 08:14:00' do
        get '/getSunlightHours', query
        expect(last_response).to be_ok
        expect(last_response.body).to include '08:14:00'
      end
    end

    context 'when an apartment is at the west-most part' do
      it 'stops receiving sunlight at 17:25:00' do
        query[:building] = 'O3'
        get '/getSunlightHours', query
        expect(last_response).to be_ok
        expect(last_response.body).to include '17:25:00'
      end
    end

    context 'when an apartment is in-between two taller buildings' do
      it 'only receives sunlight from 11:14:00 - 14:14:00' do
        query[:building] = 'O2'
        query[:apartment_number] = 1
        get '/getSunlightHours', query
        expect(last_response).to be_ok
        expect(last_response.body).to eq '11:14:00 - 14:14:00'
      end
    end

    context 'when an invalid neighbourhood name is passed' do
      it 'returns an error' do
        query[:neighbourhood] = 'alaska'
        get '/getSunlightHours', query
        response = JSON.parse(last_response.body)
        expect(response['message']).to eq 'Neighbourhood not found'
      end
    end

    context 'when an invalid building name is passed' do
      it 'returns an error' do
        query[:building] = 'alaska'
        get '/getSunlightHours', query
        response = JSON.parse(last_response.body)
        expect(response['message']).to eq 'Building not found'
      end
    end
  end

  def cache_handler
    Dalli::Client.new('localhost:11211')
  end
end
