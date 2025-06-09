#!/bin/sh
set -e

# Generate htpasswd file from environment variables
echo "Generating authentication file from environment variables..."

# Set defaults if not provided
AUTH_USERNAME=${AUTH_USERNAME:-admin}
AUTH_PASSWORD=${AUTH_PASSWORD:-changeme}

# Ensure the directory exists
mkdir -p /etc/nginx

# Create htpasswd file
htpasswd -cb /etc/nginx/.htpasswd "$AUTH_USERNAME" "$AUTH_PASSWORD"

# Set proper permissions (readable by nginx user)
chmod 644 /etc/nginx/.htpasswd
chown nginx:nginx /etc/nginx/.htpasswd

echo "✓ Authentication configured for user: $AUTH_USERNAME"
echo "✓ htpasswd file created at /etc/nginx/.htpasswd with proper permissions" 