
# syntax=docker/dockerfile:1.7

# Stage 1: Builder
FROM node:20.11-slim AS builder

WORKDIR /app

COPY app/package.json app/package-lock.json ./
RUN npm ci --omit=dev

COPY app/ ./

# Patch vulnerable proxy-addr inside the image
RUN npm install proxy-addr@2.0.8 --save-exact --omit=dev

# Stage 2: Runtime
FROM node:20.11-slim

WORKDIR /app

# Update Debian security packages
# Remove bundled npm, which is not needed at runtime
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/local/lib/node_modules/npm

COPY --from=builder /app /app

ENV NODE_ENV=production

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
 CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"

CMD ["node", "src/index.js"]
