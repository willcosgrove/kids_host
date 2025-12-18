#!/bin/bash
set -e

# Set user passwords from environment variables
if [ -n "$GRAHAM_PASSWORD" ]; then
    echo "graham:$GRAHAM_PASSWORD" | chpasswd
    echo "Set password for graham"
fi

if [ -n "$CAROLINE_PASSWORD" ]; then
    echo "caroline:$CAROLINE_PASSWORD" | chpasswd
    echo "Set password for caroline"
fi

# Ensure user directories exist with correct permissions
for user in graham caroline; do
    mkdir -p /sites/$user
    chown $user:kids /sites/$user
    chmod 755 /sites/$user
    # Create a starter index.html.erb if no index exists
    if [ ! -f /sites/$user/index.html ] && [ ! -f /sites/$user/index.html.erb ]; then
        cat > /sites/$user/index.html.erb << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
  <title>Welcome!</title>
  <style>
    body { font-family: sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; }
    h1 { color: #333; }
    .info { background: #f0f0f0; padding: 15px; border-radius: 8px; margin: 20px 0; }
  </style>
</head>
<body>
  <h1><%= rainbow("Welcome to my website!") %></h1>

  <div class="info">
    <p>The current time is: <strong><%= format_time %></strong></p>
    <p>Today's date is: <strong><%= format_date %></strong></p>
    <p>Random number: <strong><%= random(1, 100) %></strong></p>
  </div>

  <p>This page was made with Ruby! Edit this file via SFTP to make it your own.</p>
</body>
</html>
HTMLEOF
        chown $user:kids /sites/$user/index.html.erb
    fi
done

# Start sshd
/usr/sbin/sshd

# Start Puma in foreground
cd /app
exec bundle exec puma -b tcp://0.0.0.0:80 config.ru
