# Build stage
FROM node:20-slim AS builder

# Set working directory
WORKDIR /app

# Copy package files first to check which package manager to install
COPY package*.json pnpm-lock.yaml* yarn.lock* .npmrc* ./

# Install appropriate package manager and dependencies
RUN if [ -f pnpm-lock.yaml ]; then \
      npm install -g pnpm && \
      pnpm install --frozen-lockfile; \
    elif [ -f yarn.lock ]; then \
      npm install -g yarn && \
      yarn install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then \
      npm ci; \
    else \
      echo "No lockfile found. Installing dependencies with npm..." && \
      npm install; \
    fi

# Copy source files
COPY . .

# Build the application if package.json exists
RUN if [ -f package.json ]; then \
      if [ -f pnpm-lock.yaml ]; then \
        pnpm build; \
      elif [ -f yarn.lock ]; then \
        yarn build; \
      else \
        npm run build; \
      fi \
    fi

# Production stage
FROM caddy:2-alpine

# Create non-root user for security
RUN adduser -D -u 1000 caddy

# Ensure necessary directories exist and set ownership
RUN mkdir -p /data/caddy /config/caddy && \
    chown -R caddy:caddy /data/caddy /config/caddy

# Copy built files
COPY --from=builder --chown=caddy:caddy /app/dist /srv

# Embed Caddyfile with admin off and HTTP-only mode
RUN printf "{\n admin off\n }\n\
    http://:80\n{\n\
        root * /srv\n\
        file_server\n\
        @static {\n\
            file {\n\
                try_files {path} {path}/ /index.html\n\
            }\n\
            path *.css *.js *.jpg *.jpeg *.png *.gif *.ico *.svg *.woff *.woff2 *.ttf *.eot\n\
        }\n\
        header @static Cache-Control \"public, max-age=31536000, immutable\"\n\
        encode gzip zstd\n\
    }\n" > /etc/caddy/Caddyfile

# Use non-root user
USER caddy

# Expose port
EXPOSE 80

# Start Caddy with the config file
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]

