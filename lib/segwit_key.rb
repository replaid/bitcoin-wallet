require 'bitcoin'
require 'dry/initializer'
require_relative 'types'

class SegWitKey
  extend Dry::Initializer

  option :bitcoin_key, type: Types::BitcoinKey
  option :network, type: Types::Symbol.enum(:mainnet, :testnet, :signet)

  def address
    Bitcoin::Script.to_p2wpkh(@bitcoin_key.pubkey.htb).to_addr
  end

  def legacy_address
    @bitcoin_key.to_addr
  end
end
