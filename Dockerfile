FROM nginx:alpine

# Install bash since alpine uses ash by default, and we wrote a bash script
RUN apk add --no-cache bash


# Setup Debian-like sites-available and sites-enabled structure for Nginx
RUN mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled \
    && sed -i '/include \/etc\/nginx\/conf\.d\/\*\.conf;/a \    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf

# Copy our management script
COPY nginx-manager.sh /usr/local/bin/nginx-manager
RUN chmod +x /usr/local/bin/nginx-manager

# The container will run standard nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
