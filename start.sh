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

# Ensure chroot directory structure exists and has correct permissions
# Chroot requires: root owns the chroot dir, user owns subdirs inside
for user in graham caroline; do
    mkdir -p /sites/$user/public_html
    # Chroot directory must be owned by root (required for chroot)
    chown root:root /sites/$user
    chmod 755 /sites/$user
    # User owns their public_html directory where they upload files
    chown $user:kids /sites/$user/public_html
    chmod 755 /sites/$user/public_html
    # Create a starter index.html if none exists
    if [ ! -f /sites/$user/public_html/index.html ]; then
        echo "<html><body><h1>Welcome to $user's website!</h1></body></html>" > /sites/$user/public_html/index.html
        chown $user:kids /sites/$user/public_html/index.html
    fi
done

# Start sshd
/usr/sbin/sshd

# Start nginx in foreground
exec nginx -g 'daemon off;'
