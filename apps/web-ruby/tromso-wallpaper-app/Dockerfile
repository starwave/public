# Build stage
FROM ruby:3.3-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache build-base

# Copy Gemfile
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Production stage
FROM ruby:3.3-alpine

WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache tzdata

# Copy installed gems from builder
COPY --from=builder /app/vendor/bundle /app/vendor/bundle
COPY --from=builder /app/.bundle /app/.bundle

# Copy application code
COPY . .

# Set bundle config for production
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test'

# Expose port
EXPOSE 3001

# Set environment
ENV RACK_ENV=production
ENV PORT=3001

# Start server
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
