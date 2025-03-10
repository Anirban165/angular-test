FROM node:20-slim AS builder
WORKDIR /app

# Copy package files for dependency installation
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the application
COPY . .

# Build the Angular application in production mode
RUN npm run build -- --configuration production

# Production stage
FROM caddy:2-alpine

# Set build arg for build directory
ARG BUILD_DIR=""

# Setup user and directories
RUN adduser -D -u 1000 caddy && \
    mkdir -p /data/caddy /config/caddy /srv && \
    chown -R caddy:caddy /data/caddy /config/caddy /srv

# Copy built files from the builder stage
COPY --from=builder --chown=caddy:caddy /app/dist/*/browser /srv

# Create Caddyfile
COPY <<EOF /etc/caddy/Caddyfile
{
    admin off
    storage file_system {
        root /data/caddy
    }
}

http://:80 {
    root * /srv
    file_server

    header Cache-Control "public, max-age=3600"
    
    @static {
        path *.css *.js *.jpg *.jpeg *.png *.gif *.ico *.svg *.woff *.woff2
    }
    header @static Cache-Control "public, max-age=31536000"  # Cache for 1 year
    
    encode gzip zstd
    
    handle_path /* {
        file_server {
            precompressed br gzip
        }
    }
}
EOF

# Switch to non-root user
USER caddy

# Expose port
EXPOSE 80

# Start Caddy
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]