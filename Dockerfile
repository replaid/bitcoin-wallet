FROM ruby:3.2
WORKDIR /app
COPY Gemfile* .
RUN bundle install
COPY . .
RUN chmod +x bin/wallet_cli.rb
ENTRYPOINT ["ruby", "bin/wallet_cli.rb"]
