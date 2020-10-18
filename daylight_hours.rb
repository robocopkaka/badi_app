# frozen_string_literal: true

# class for methods needed for both `init` and `getDaylightHours`
class DaylightHours
  @left_time_hash = {
    '0' => '08:14:00',
    '1' => '08:14:00',
    '2' => '08:14:00',
    '3' => '08:44:00',
    '4' => '08:44:00',
    '5' => '08:44:00',
    '6' => '09:14:00',
    '7' => '09:14:00',
    '8' => '09:14:00',
    '9' => '09:44:00',
    '10' => '09:44:00',
    '11' => '09:44:00',
    '12' => '10:14:00',
    '13' => '10:14:00',
    '14' => '10:14:00',
    '15' => '10:44:00',
    '16' => '10:44:00',
    '17' => '10:44:00'
  }

  @right_time_hash = {
    '0' => '17:25:00',
    '1' => '17:25:00',
    '2' => '17:25:00',
    '3' => '16:44:00',
    '4' => '16:44:00',
    '5' => '16:44:00',
    '6' => '16:14:00',
    '7' => '16:14:00',
    '8' => '16:14:00',
    '9' => '15:44:00',
    '10' => '15:44:00',
    '11' => '15:44:00',
    '12' => '15:14:00',
    '13' => '15:14:00',
    '14' => '15:14:00',
    '15' => '14:44:00',
    '16' => '14:44:00',
    '17' => '14:44:00'
  }

  def self.prep_array(params)
    error_message = validate_apartment_height(params)
    return { error:  error_message } if error_message

    main_array = []
    neighbourhoods_hash =
      Hash.new { |key, value| key[value] = Hash.new(&key.default_proc) }
    params.each do |neighbourhood|
      nb_name = neighbourhood['neighbourhood']
      neighbourhoods_hash[nb_name]['start_index'] = main_array.length
      neighbourhood['buildings'].each do |building|
        main_array.push Array(0..building['apartments_count'] - 1)
        neighbourhoods_hash[nb_name]['buildings'][building['name']] = main_array.length - 1
      end
      neighbourhoods_hash[nb_name]['end_index'] = main_array.length - 1
    end
    { hash: neighbourhoods_hash.to_json, array: main_array }
  end

  def self.higher_to_left?(cache_handler, building_index, apartment_number, first)
    array = cache_handler.get(:nb_array)
    return true if building_index == first

    (building_index - 1).downto(first) do |index|
      return false unless array[index][apartment_number].nil?
    end

    true
  end

  def self.higher_to_right?(cache_handler, building_index, apartment_number, last)
    array = cache_handler.get(:nb_array)
    return true if building_index == last

    (building_index + 1).upto(last) do |index|
      return false unless array[index][apartment_number].nil?
    end

    true
  end

  def self.add_hours_left(apartment_number, building_index, first)
    array = []
    if building_index == first
      array.push(0)
    else
      array.push(apartment_number)
    end
    array
  end

  def self.add_hours_right(apartment_number, building_index, last)
    array = []
    if building_index == last
      array.push(0)
    else
      array.push(apartment_number)
    end
    array
  end

  def self.compute_total_hours(east_hours, west_hours)
    return '11:14:00-14:14:00' if east_hours.empty? & west_hours.empty?

    start_hour_east = east_hours.first.to_s
    end_hour_west = west_hours.first.to_s

    return "#{@left_time_hash[start_hour_east]} - 14:14:00" if west_hours.empty?
    return "11:14:00 - #{@right_time_hash[end_hour_west]}" if east_hours.empty?

    "#{@left_time_hash[start_hour_east]} - #{@right_time_hash[end_hour_west]}"
  end

  def self.validate_apartment_height(params)
    params.each do |nb|
      heights = nb['buildings']
                .map { |val| val['apartments_count'] }
                .sort
      if heights.last > 18
        return "You have an apartment with height higher \
                than 18 in #{nb['neighbourhood']}. Maximum \
                number of apartments allowed for a building is 18"
      end
    end
  end
end
