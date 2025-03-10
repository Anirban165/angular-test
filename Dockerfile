FROM node:18-alpine AS base

FROM base AS builder

RUN apk add --no-cache libc6-compat

WORKDIR /app

COPY angular.json package*.json pnpm-lock.yaml* yarn.lock* .npmrc* ./

RUN [ -f angular.json ] || (echo "angular.json not found. Exiting..." && exit 1)

RUN corepack prepare pnpm@latest --activate && corepack enable pnpm

ARG INSTALL_CMD="npm install"

RUN if [ -n "$INSTALL_CMD" ]; then eval "$INSTALL_CMD"; \
    elif [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile; \
    elif [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci --force; \
    elif [ -f package.json ]; then npm install; \
    else echo "Lockfile not found." && exit 1; \
    fi

COPY . .

ARG ENV_BASE64="UE9SVD0zMDAKQVBJX1VSTD1odHRwczovL2FwaS5tdWxsdGlwbHkub3Jn"
RUN echo "$ENV_BASE64" | base64 -d > .env

ARG BUILD_CMD="npm run build"

ENV NG_CLI_ANALYTICS=false

RUN if [ -n "$BUILD_CMD" ]; then eval "$BUILD_CMD"; \
    elif grep -q '"build"' package.json; then \
      [ -f pnpm-lock.yaml ] && pnpm run build -- --configuration=production|| \
      [ -f yarn.lock ] && yarn build --configuration=production || \
      npm run build -- --configuration=production; \
    else \
      echo "No build command found. Skipping build step."; \
    fi

FROM base AS runner

RUN apk add --no-cache jq curl

ARG BUILD_DIR=""

WORKDIR /app

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

COPY angular.json .

# RUN --mount=type=bind,from=builder,source=/app,target=/mnt \
#     if [ -n "${BUILD_DIR}" ]; then \
#         if [ ! -d "/mnt/${BUILD_DIR}" ]; then \
#             echo "Error: Build directory /mnt/${BUILD_DIR} does not exist" && \
#             exit 1; \
#         fi && \
#         cp -r /mnt/"${BUILD_DIR}"/* .; \
#     else \
#         PROJECT_NAME=$(jq -r '.projects | keys | .[0]' angular.json) && \
#         OUTPUT_PATH=$(jq -r ".projects.\"${PROJECT_NAME}\".architect.build.options.outputPath" angular.json) && \
#         cp -r /mnt/"${OUTPUT_PATH}"/* .; \
#     fi && rm angular.json

COPY --from=builder /app /tmp
RUN if [ -n "${BUILD_DIR}" ]; then \
        if [ ! -d "${BUILD_DIR}" ]; then \
            echo "Error: Build directory ${BUILD_DIR} does not exist" && exit 1; \
        fi && \
        cp -r "/tmp/${BUILD_DIR}"/* .; \
    else \
        PROJECT_NAME=$(jq -r '.projects | keys | .[0]' angular.json) && \
        OUTPUT_PATH=$(jq -r ".projects.\"${PROJECT_NAME}\".architect.build.options.outputPath" angular.json) && \
        cp -r "/tmp/${OUTPUT_PATH}"/* .; \
    fi && rm angular.json && rm -rf /tmp


RUN curl -sO https://public-sets.b-cdn.net/runner.angular && chown -R nodejs:nodejs .
USER nodejs

ENV NODE_ENV=production
ENV PORT="3000"
ENV HOSTNAME="0.0.0.0"

CMD ["node", "runner.angular"]