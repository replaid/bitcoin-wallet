FROM ruby:3.2
WORKDIR /app

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential curl && \
    rm -rf /var/lib/apt/lists/*

# Set up project
COPY Gemfile* .
RUN bundle install && \
    mkdir -p /app/data && \
    chmod 0700 /app/data

# Copy all files
COPY . .

# Ensure the script is executable
RUN chmod +x bin/wallet_cli.rb

ENTRYPOINT ["ruby", "bin/wallet_cli.rb"]
