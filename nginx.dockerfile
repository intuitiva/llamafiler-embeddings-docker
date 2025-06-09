FROM nginx:alpine

# Install apache2-utils for htpasswd
RUN apk add --no-cache apache2-utils

# Copy entrypoint script with proper naming convention
COPY nginx-entrypoint.sh /docker-entrypoint.d/40-generate-htpasswd.sh
RUN chmod +x /docker-entrypoint.d/40-generate-htpasswd.sh

# Create directory and set permissions for htpasswd file
RUN mkdir -p /etc/nginx && chown nginx:nginx /etc/nginx 