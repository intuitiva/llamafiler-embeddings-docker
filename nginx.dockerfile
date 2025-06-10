FROM nginx:1.28-alpine

# Install apache2-utils for htpasswd
#RUN apk add --no-cache apache2-utils

# Copy nginx configuration
COPY nginx.conf /etc/nginx/templates/nginx.conf.template

# Remove default configuration to prevent conflicts
RUN rm -f /etc/nginx/conf.d/default.conf

# Copy entrypoint script with proper naming convention
#COPY nginx-entrypoint.sh /docker-entrypoint.d/40-generate-htpasswd.sh
#RUN chmod +x /docker-entrypoint.d/40-generate-htpasswd.sh

# Optionally, add a health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost || exit 1
    
# Expose the port nginx is running on
EXPOSE 80

# Create directory and set permissions for htpasswd file
#RUN mkdir -p /etc/nginx && chown nginx:nginx /etc/nginx 