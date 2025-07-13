require 'fileutils'
require 'bitcoin'
Bitcoin.chain_params = :signet
require 'money'
Money.rounding_mode = BigDecimal::ROUND_HALF_UP
require 'net/http'
require 'wif_file'

class Wallet
  attr_reader :wif_file

  def initialize(wif_file: WIFFile.new)
    @wif_file = wif_file
  end

  def ensure_key_file
    wif_file.ensure_exists! do
      Bitcoin::Key.generate
    end
  end

  def load_key
    Bitcoin::Key.from_wif(File.read(wif_file.filename))
  end

  def fetch_balance
    address = load_key.to_addr
    uri = URI("https://mempool.space/signet/api/address/#{address}")
    satoshi_balance = JSON.parse(Net::HTTP.get(uri))["chain_stats"]["funded_txo_sum"]
    Money.new(satoshi_balance, 'BTC')
  end
end
