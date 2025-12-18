require "roda"
require "erb"
require_relative "helpers"

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

    # Evaluate ERB in context's instance so `def` works naturally
    context = ErbContext.new(user)
    template = File.read(path)
    context.instance_eval do
      ERB.new(template).result(binding)
    end
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
  include ErbHelpers

  attr_reader :user

  def initialize(user)
    @user = user
  end
end
