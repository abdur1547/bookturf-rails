module Venues::Helpers
  def default_operating_hours
    (0..6).map do |day|
      {
        day_of_week: day,
        opens_at: "09:00",
        closes_at: "23:00",
        is_closed: false,
        is_open_24h: false
      }
    end
  end

  def operating_hours_params(hours)
      same_time = hours[:closes_at] == hours[:opens_at]
      opens_at = same_time ? nil : hours[:opens_at]
      closes_at = same_time ? nil : hours[:closes_at]
      is_open_24h = hours[:is_open_24h] || false
      {
        day_of_week: hours[:day_of_week],
        opens_at: opens_at,
        closes_at: closes_at,
        is_closed: hours[:is_closed] || false,
        is_open_24h: is_open_24h || same_time
      }
  end
end
