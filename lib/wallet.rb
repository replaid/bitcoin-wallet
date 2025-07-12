require 'fileutils'
require 'bitcoin'
Bitcoin.chain_params = :signet
require 'money'
Money.rounding_mode = BigDecimal::ROUND_HALF_UP
require 'net/http'
require 'wif_file'

class Wallet
  KEY_FILENAME = 'wallet.key'

  def ensure_key_file(directory: Dir.pwd)
    file = WIFFile.new(directory: directory)
    file.ensure_exists! do
      Bitcoin::Key.generate
    end
  end

  def self.load_key
    Bitcoin::Key.from_wif(File.read(KEY_FILENAME))
  end

  def fetch_balance
    key = self.class.load_key
    address = key.to_addr
    uri = URI("https://mempool.space/signet/api/address/#{address}")
    satoshi_balance = JSON.parse(Net::HTTP.get(uri))["chain_stats"]["funded_txo_sum"]
    Money.new(satoshi_balance, 'BTC')
  end
end
