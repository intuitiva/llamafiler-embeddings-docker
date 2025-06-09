#!/bin/sh

# Generate htpasswd file from environment variables
echo "Generating authentication file from environment variables..."

# Set defaults if not provided
AUTH_USERNAME=${AUTH_USERNAME:-admin}
AUTH_PASSWORD=${AUTH_PASSWORD:-changeme}

# Create htpasswd file
htpasswd -cb /etc/nginx/.htpasswd "$AUTH_USERNAME" "$AUTH_PASSWORD"

# Set proper permissions
chmod 600 /etc/nginx/.htpasswd

echo "✓ Authentication configured for user: $AUTH_USERNAME" 