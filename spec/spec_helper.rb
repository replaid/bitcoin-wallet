require 'bundler/setup'
require 'dry/monads'
require 'dry/container'
require 'rspec'

# Initialize container
require_relative '../system/container'

# Auto-require all Ruby files in lib
Dir[File.join(__dir__, '../lib/**/*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.include Dry::Monads[:result]

  config.before(:suite) do
    # Initialize all container dependencies
    Container.resolve('bitcoin')
    Container.resolve('money')
  end
end

require_relative './support/utxo_helpers'

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
end

require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.include UTXOHelpers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
