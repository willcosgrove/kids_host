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
    # Create a starter index.html if none exists
    if [ ! -f /sites/$user/index.html ]; then
        echo "<html><body><h1>Welcome to $user's website!</h1></body></html>" > /sites/$user/index.html
        chown $user:kids /sites/$user/index.html
    fi
done

# Start sshd
/usr/sbin/sshd

# Start nginx in foreground
exec nginx -g 'daemon off;'
