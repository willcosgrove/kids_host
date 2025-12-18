# Kids Hosting

A simple hosting platform for kids to learn web development - just like the 90s, but with Ruby instead of PHP.

Kids get their own subdomain and can upload HTML, CSS, JS, and images via SFTP. They can also create `.html.erb` files to use dynamic Ruby code in their pages.

## Features

- **SFTP Access**: Kids upload files with any SFTP client (Cyberduck, FileZilla, etc.)
- **Ruby/ERB Support**: Create `.html.erb` files with dynamic content using `<%= %>` tags
- **Pretty URLs**: `page.html` automatically renders `page.html.erb` if it exists
- **Kid-Friendly Helpers**: Built-in functions like `rainbow()`, `random()`, `days_until()`

## Example ERB Page

```erb
<!DOCTYPE html>
<html>
<body>
  <h1><%= rainbow("Welcome to my site!") %></h1>
  <p>You are visitor #<%= random(1, 9999) %></p>
  <p>Days until Christmas: <%= days_until(12, 25) %></p>

  <% if Time.now.hour < 12 %>
    <p>Good morning!</p>
  <% else %>
    <p>Good afternoon!</p>
  <% end %>
</body>
</html>
```

## Setup Your Own

### Prerequisites

- A server (Mac Mini, Raspberry Pi, VPS, etc.)
- Docker installed on the server
- [Kamal](https://kamal-deploy.org/) installed locally
- A domain with wildcard DNS pointing to your server (or use Cloudflare Tunnel)
- A Docker Hub account (free)

### 1. Clone and Configure

```bash
git clone https://github.com/yourname/kids_hosting.git
cd kids_hosting

# Copy the example config
cp config/deploy.example.yml config/deploy.yml
```

### 2. Edit config/deploy.yml

The main configuration is at the top of the file:

```ruby
<%
kids = {
  "alice" => "alice-sftp-password",
  "bob" => "bob-sftp-password"
}
domain = "example.com"
%>
```

Then update these sections:

```yaml
# Your Docker Hub username
image: YOUR_DOCKERHUB_USERNAME/kids-hosting
registry:
  username: YOUR_DOCKERHUB_USERNAME

# Your server
servers:
  web:
    hosts:
      - your-server.local    # or IP address
ssh:
  user: your-ssh-user

# Where to store kids' files on the host
volumes:
  - /path/to/kids-sites:/sites

# Change to amd64 for Intel/AMD servers
builder:
  arch: arm64
```

### 3. Set Up Secrets

```bash
cp .kamal/secrets.example .kamal/secrets
```

Edit `.kamal/secrets` and add your Docker Hub token:

```
KAMAL_REGISTRY_PASSWORD=your_docker_hub_token
```

(Get a token at https://hub.docker.com/settings/security)

### 4. Deploy

```bash
kamal deploy
```

### 5. Set Up DNS

Point wildcard subdomains to your server:

- `*.example.com` → your server's IP

Or use Cloudflare Tunnel for automatic HTTPS without exposing your home IP.

## Connecting via SFTP

Kids connect with any SFTP client:

- **Host**: your-server.local (or IP)
- **Port**: 2222
- **Username**: their name (e.g., `alice`)
- **Password**: the password you set in deploy.yml

## Available ERB Helpers

| Helper | Example | Output |
|--------|---------|--------|
| `rainbow(text)` | `<%= rainbow("Hi!") %>` | Colorful text |
| `random(min, max)` | `<%= random(1, 100) %>` | Random number |
| `pick(a, b, c)` | `<%= pick("red", "blue") %>` | Random choice |
| `format_time` | `<%= format_time %>` | "03:45 PM" |
| `format_date` | `<%= format_date %>` | "December 18, 2025" |
| `days_until(m, d)` | `<%= days_until(12, 25) %>` | Days until date |
| `year` | `<%= year %>` | Current year |
| `h(text)` | `<%= h(input) %>` | HTML escape |
| `user` | `<%= user %>` | Current username |

## Background

This project replicates how I learned web development as a kid in the 90s. My parents let me sign up for a free web host, and I would FTP into it and add my HTML files, and later PHP. Now my kids can have the same experience, but with Ruby/ERB instead of PHP.

## License

MIT
