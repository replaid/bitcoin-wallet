require 'dry/system'
require 'dry/container'
require 'dry/auto_inject'

require 'dry/monads'
require 'dry/types'

require_relative '../lib/types'

require_relative '../lib/core/services/wallet_service'
require_relative '../lib/infrastructure/wif_file_adapter'
require_relative '../lib/infrastructure/mempool_space_adapter'
require_relative '../lib/segwit_key'
require_relative '../lib/wallet'
require_relative '../lib/wif_file'

module Infrastructure
  # Define adapters here if needed
end

class Container < Dry::System::Container
  extend Dry::Container::Mixin

  register('mempool.adapter') { Infrastructure::MempoolSpaceAdapter.new }
  register('key_store') { Infrastructure::WIFFileAdapter.new }

  register('wif_file') { WIFFile.new }
  register('wallet') { Wallet.new(wif_file: resolve('wif_file')) }
end

Import = Dry::AutoInject(Container)
