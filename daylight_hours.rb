# frozen_string_literal: true

require_relative 'time_hashes'
# class for methods needed for both `init` and `getDaylightHours`
class DaylightHours
  def self.prep_array(params)
    main_array = []
    neighbourhoods_hash =
      Hash.new { |key, value| key[value] = Hash.new(&key.default_proc) }
    params.each do |neighbourhood|
      nb_name = neighbourhood['neighbourhood']
      create_array(main_array, neighbourhoods_hash, neighbourhood)
      neighbourhoods_hash[nb_name]['index'] = main_array.length - 1
      neighbourhoods_hash[nb_name]['apartments_height'] =
        neighbourhood['apartments_height']
    end
    { hash: neighbourhoods_hash.to_json, array: main_array }
  end

  def self.create_array(main_array, neighbourhoods_hash, neighbourhood)
    nb_array = []
    name = neighbourhood['neighbourhood']
    neighbourhood['buildings'].each do |building|
      nb_array.push Array(0..building['apartments_count'] - 1)

      neighbourhoods_hash[name]['buildings'][building['name']] =
        nb_array.length - 1
    end
    main_array.push(nb_array)
  end

  def self.higher_to_left?(cache_handler, building, apartment_number, nb_index)
    array = cache_handler.get(:nb_array)[nb_index]
    return true if building.zero?

    (building - 1).downto(0) do |index|
      return false unless array[index][apartment_number].nil?
    end

    true
  end

  def self.higher_to_right?(cache_handler, building, apartment_number, nb_index)
    array = cache_handler.get(:nb_array)[nb_index]
    return true if building == array.length - 1

    (building + 1).upto(array.length - 1) do |index|
      return false unless array[index][apartment_number].nil?
    end

    true
  end

  def self.add_hours_left(apartment_number, building_index)
    array = []
    if building_index.zero?
      array.push(0)
    else
      array.push(apartment_number)
    end
    array
  end

  def self.add_hours_right(apartment_number, building_index, last_index)
    array = []
    if building_index == last_index
      array.push(0)
    else
      array.push(apartment_number)
    end
    array
  end

  def self.compute_total_hours(east_hours, west_hours)
    return '11:14:00 - 14:14:00' if east_hours.empty? & west_hours.empty?

    start_hour_east = east_hours.first.to_s
    end_hour_west = west_hours.first.to_s

    return "#{LEFT_TIME_HASH[start_hour_east]} - 14:14:00" if west_hours.empty?
    return "11:14:00 - #{RIGHT_TIME_HASH[end_hour_west]}" if east_hours.empty?

    "#{LEFT_TIME_HASH[start_hour_east]} - #{RIGHT_TIME_HASH[end_hour_west]}"
  end

  def self.validate_apartment_height(params)
    params.each do |nb|
      heights = nb['buildings'].map { |val| val['apartments_count'] }.sort
      if heights.last > 18
        return "You have an apartment with height higher \
                than 18 in #{nb['neighbourhood']}. Maximum \
                number of apartments allowed for a building is 18"
      end
    end

    nil
  end
end
