# Builder Stage
FROM node:22-alpine AS builder
WORKDIR /app

ENV HTTP_PROXY http://192.168.3.32:10809
ENV HTTPS_PROXY http://192.168.3.32:10809
ENV NO_PROXY localhost,127.0.0.1
ENV http_proxy http://192.168.3.32:10809
ENV https_proxy http://192.168.3.32:10809
ENV no_proxy localhost,127.0.0.1

# Install pnpm
RUN npm install -g pnpm

# Copy package.json and pnpm-lock.yaml
COPY package.json pnpm-lock.yaml* ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the application code
COPY . .

# Build the Next.js application
RUN pnpm build

# Production Stage
FROM node:22-alpine AS runner
WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Set node environment to production
ENV NODE_ENV=production

# Copy necessary files from builder stage
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Copy the startup script
COPY startup.sh /app/startup.sh

# Ensure the startup script is executable
RUN chmod +x /app/startup.sh

# Expose the port the app runs on
EXPOSE 3000

# Define the command to run the startup script
CMD ["/app/startup.sh"]
