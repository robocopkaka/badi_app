# README

## Prerequisites
* Ruby 2.5.3
* Memcached

I made use of Sinatra for this assessment

## Installation steps
* Clone this repository
* `cd` into it on your local machine
* Run `bundle install` to install all gems
* Start the server with `shotgun config.ru -p 3000`

## Endpoints provided
* `POST /init`
* `GET /getSunlightHours`

## Tests
* Run `bundle exec rspec` to run all tests

## Assumptions
* Entry point for the application is [base_app.rb](base_app.rb)
* I assumed the maximum number apartments a building can have is `18`
* I picked 18 after by settling on 30 minute time intervals between `08:14:00 - 17:25:00`
* For `/init` to only be run once, I cached the values from it using `memcached` 
* I created a hash map that allows you easily find a building in a neighborhood by name.
* I assumed all neighbourhoods were in an `N x N` array and that the sun rose from say `a(0,0) to a(0,18)` which covers
times from `08:14:00 - 11:14:00`. It then travels westward from say, `a(0,18) to z(18,18)` which would likely cover
hours from `11:14:00 - 14:14:00`. It then sets from say, `z(18,18) to z(18,0)` which would cover hours from
`14:44:00 - 17:25:00`
* I assumed that the apartments in a building on the easternmost side of a neighbourhood all receive sunlight 
between `08:14:00 - 11:14`
* I assumed that the apartments in a building on the westernmost side of a neighbourhood all receive sunlight 
between `14:44:00 - 17:25:00`
* I assumed that all apartments receive sunlight between `11:14:00 - 14:14:00`
* Following the instructions, I assumed that buildings in one neighbourhood can't
cast shadows on buildings in a different one
* For each apartment that you're trying to get sunlight hours for, I check to see if there's a building
on either side of it in the neighbourhood that's higher. If there is on any side, I factor it in when deciding the amount of sunlight
the apartment should get
* I made use of two static hashes for times which have values separated by intervals of 30 minutes
