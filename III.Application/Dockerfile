# Pull the minimal Ubuntu image
FROM nginx

# Copy the Nginx config
COPY default.conf /etc/nginx/conf.d/

# Expose the port for access
EXPOSE 80/tcp

# Run the Nginx server
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]