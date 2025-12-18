#!/bin/bash
set -e

# Validate required environment variables
if [ -z "$KIDS" ]; then
    echo "ERROR: KIDS environment variable is required (e.g., KIDS=alice,bob)"
    exit 1
fi

if [ -z "$DOMAIN" ]; then
    echo "ERROR: DOMAIN environment variable is required (e.g., DOMAIN=example.com)"
    exit 1
fi

# Parse KIDS env var (comma-separated: "alice,bob")
IFS=',' read -ra KIDS_ARRAY <<< "$KIDS"

# Parse KIDS_PASSWORDS env var (format: "alice:pass1,bob:pass2")
declare -A PASSWORDS
if [ -n "$KIDS_PASSWORDS" ]; then
    IFS=',' read -ra PASS_PAIRS <<< "$KIDS_PASSWORDS"
    for pair in "${PASS_PAIRS[@]}"; do
        IFS=':' read -r name pass <<< "$pair"
        PASSWORDS[$name]="$pass"
    done
fi

# Create each user and set up their environment
for kid in "${KIDS_ARRAY[@]}"; do
    # Trim whitespace
    kid=$(echo "$kid" | xargs)

    # Create user if doesn't exist
    if ! id "$kid" &>/dev/null; then
        adduser -D -G kids "$kid"
        echo "Created user: $kid"
    fi

    # Set password if provided
    if [ -n "${PASSWORDS[$kid]}" ]; then
        echo "$kid:${PASSWORDS[$kid]}" | chpasswd
        echo "Set password for $kid"
    else
        echo "WARNING: No password set for $kid (SFTP login will fail)"
    fi

    # Ensure user directory exists with correct permissions
    mkdir -p /sites/$kid
    chown $kid:kids /sites/$kid
    chmod 755 /sites/$kid

    # Create a starter index.html.erb if no index exists
    if [ ! -f /sites/$kid/index.html ] && [ ! -f /sites/$kid/index.html.erb ]; then
        cat > /sites/$kid/index.html.erb << 'HTMLEOF'
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
        chown $kid:kids /sites/$kid/index.html.erb
        echo "Created starter page for $kid"
    fi
done

echo "Kids hosting ready for: ${KIDS_ARRAY[*]}"
echo "Domain: $DOMAIN"

# Start sshd
/usr/sbin/sshd

# Start Puma in foreground
cd /app
exec bundle exec puma -b tcp://0.0.0.0:80 config.ru
