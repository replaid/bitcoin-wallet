require 'dry/system'
require 'dry/container'
require 'dry/auto_inject'
require 'dry/types'

module Infrastructure
  # Define adapter interfaces
  class MempoolSpaceAdapter; end
  class WifFileAdapter; end
end

class Container
  extend Dry::Container::Mixin

  register('bitcoin') do
    require 'bitcoin'
    Bitcoin.chain_params = :signet
    Bitcoin
  end

  register('money') do
    require 'money'
    Money.rounding_mode = BigDecimal::ROUND_HALF_UP
    Money.locale_backend = nil
    Money
  end

  register('mempool.adapter') { Infrastructure::MempoolSpaceAdapter.new }
  register('key_store') { Infrastructure::WifFileAdapter.new }
end

# Set up auto-injection
Import = Dry::AutoInject(Container)
