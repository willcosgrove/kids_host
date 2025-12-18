# Helper methods available in ERB templates
module ErbHelpers
  # Get current time
  def now
    Time.now
  end

  # Random number between min and max
  def random(min = 1, max = 100)
    rand(min..max)
  end

  # Pick a random item from an array
  def pick(*items)
    items.flatten.sample
  end

  # Repeat something n times
  def repeat(n, &block)
    n.times.map(&block).join
  end

  # Simple HTML escaping
  def h(text)
    ERB::Util.html_escape(text)
  end

  # Format a date nicely
  def format_date(time = Time.now)
    time.strftime("%B %d, %Y")
  end

  # Format time nicely
  def format_time(time = Time.now)
    time.strftime("%I:%M %p")
  end

  # Days until a date (for countdowns)
  def days_until(month, day, year = nil)
    year ||= Time.now.year
    target = Time.new(year, month, day)
    target = Time.new(year + 1, month, day) if target < Time.now
    ((target - Time.now) / 86400).ceil
  end

  # How many years old (given birthdate)
  def years_old(year, month, day)
    target = Time.new(year, month, day)
    ((Time.now - target) / 31536000).floor
  end

  # Rainbow text - wraps each letter in a span with a color
  def rainbow(text)
    colors = %w[red orange yellow green blue indigo violet]
    text.chars.map.with_index do |char, i|
      if char == " "
        " "
      else
        %(<span style="color: #{colors[i % colors.length]}">#{h(char)}</span>)
      end
    end.join
  end

  # Current year (for copyright)
  def year
    Time.now.year
  end
end
