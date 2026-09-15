# Use a maintained LTS base image (node:16 is end-of-life).
FROM node:20-alpine

WORKDIR /app

# Install dependencies first for better layer caching.
# Copy lockfile too so `npm ci` can run reproducibly.
COPY package*.json ./
RUN npm ci --omit=dev

# Copy application source.
COPY . .

# Run as the built-in non-root user for a smaller attack surface.
USER node

EXPOSE 3000

CMD ["npm", "run", "start"]
