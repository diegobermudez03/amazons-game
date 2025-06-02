# Use an official Nginx image to serve static files
FROM nginx:alpine

# Copy the built Flutter web app to the Nginx html directory
COPY build/web /usr/share/nginx/html

# Expose port 80 for the web server
EXPOSE 80

# Start Nginx when the container launches
CMD ["nginx", "-g", "daemon off;"]
