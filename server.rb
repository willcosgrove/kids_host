require "roda"
require "erb"
require "tilt"

class KidsHosting < Roda
  # Configuration from environment variables
  DOMAIN = ENV.fetch("DOMAIN") { raise "DOMAIN environment variable is required" }
  KIDS = ENV.fetch("KIDS") { raise "KIDS environment variable is required" }.split(",").map(&:strip)

  raise "KIDS cannot be empty" if KIDS.empty?

  MIME_TYPES = {
    "html" => "text/html; charset=utf-8",
    "htm"  => "text/html; charset=utf-8",
    "css"  => "text/css",
    "js"   => "application/javascript",
    "json" => "application/json",
    "png"  => "image/png",
    "jpg"  => "image/jpeg",
    "jpeg" => "image/jpeg",
    "gif"  => "image/gif",
    "svg"  => "image/svg+xml",
    "ico"  => "image/x-icon",
    "webp" => "image/webp",
    "woff" => "font/woff",
    "woff2" => "font/woff2",
    "ttf"  => "font/ttf",
    "pdf"  => "application/pdf",
    "txt"  => "text/plain"
  }.freeze

  plugin :halt

  route do |r|
    # Health check endpoint - works on any host
    r.get "up" do
      response["Content-Type"] = "text/plain"
      "OK"
    end

    # Determine user from hostname (wildcard subdomain matching)
    # e.g., alice.example.com with DOMAIN=example.com -> user "alice"
    host = request.host.to_s.downcase.split(":").first  # Remove port if present
    user = host.sub(".#{DOMAIN}", "")

    # Verify this is a valid kid
    unless KIDS.include?(user)
      response.status = 404
      next "Not Found - Unknown user"
    end

    site_root = "/sites/#{user}"

    # Serve the request
    r.root do
      serve_path(site_root, "index.html", user)
    end

    r.on do
      path = r.remaining_path.sub(%r{\A/}, "")  # Remove leading slash
      serve_path(site_root, path, user)
    end
  end

  private

  def serve_path(site_root, path, user)
    # Security: prevent directory traversal
    path = path.gsub("..", "")

    # Handle directory requests (add index.html)
    if path.empty? || path.end_with?("/")
      path = "#{path}index.html"
    end

    full_path = File.join(site_root, path)

    # Determine the file extension
    ext = File.extname(path).delete(".").downcase

    # Block direct access to .erb files
    if ext == "erb"
      response.status = 404
      return "Not Found"
    end

    # Pretty URL logic for .html requests (or no extension)
    if ext == "html" || ext == "htm" || ext.empty?
      # For requests like "page.html" or "page", check for .erb version first
      if ext == "html" || ext == "htm"
        base_path = full_path.sub(/\.html?\z/, "")
      else
        base_path = full_path
      end

      erb_path = "#{base_path}.html.erb"
      html_path = "#{base_path}.html"
      htm_path = "#{base_path}.htm"

      if File.file?(erb_path)
        return render_erb(erb_path, user)
      elsif File.file?(html_path)
        return serve_static(html_path, "html")
      elsif File.file?(htm_path)
        return serve_static(htm_path, "htm")
      end
    else
      # Static file
      if File.file?(full_path)
        return serve_static(full_path, ext)
      end
    end

    # Not found
    response.status = 404
    "Not Found"
  end

  def render_erb(path, user)
    response["Content-Type"] = "text/html; charset=utf-8"

    # Create a binding with helper methods
    context = ErbContext.new(user)
    template = Tilt::ERBTemplate.new(path)
    template.render(context)
  rescue StandardError => e
    response.status = 500
    "<h1>Error</h1><pre>#{ERB::Util.html_escape(e.message)}</pre>"
  end

  def serve_static(path, ext)
    content_type = MIME_TYPES[ext] || "application/octet-stream"
    response["Content-Type"] = content_type
    File.read(path)
  end
end

# Helper context for ERB templates
class ErbContext
  attr_reader :user

  def initialize(user)
    @user = user
  end

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
