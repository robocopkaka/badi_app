class DaylightHours
  attr_accessor :neighbourhoods

  def initialize(neighbourhoods)
    @neighbourhoods = neighbourhoods
  end
  
  def daylight_hours
    @neighbourhoods
  end
end