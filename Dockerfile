# Dockerfile
FROM ruby:3.2
WORKDIR /app

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential curl && \
    rm -rf /var/lib/apt/lists/*

# Set up custom gem path
ENV BUNDLE_PATH=/app/.bundle
ENV BUNDLE_HOME=/app/.bundle
RUN bundle config set path '/app/.bundle'

# Set up project
COPY Gemfile* .
RUN bundle install && \
    mkdir -p /app/data /app/.bundle && \
    chmod 0700 /app/data /app/.bundle

# Copy all files
COPY . .

# Ensure the script is executable
RUN chmod +x bin/wallet_cli.rb

# Set entrypoint to wallet script
ENTRYPOINT ["ruby", "bin/wallet_cli.rb"]

# Default command
CMD ["help"]
