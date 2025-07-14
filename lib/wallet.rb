require 'bitcoin'
Bitcoin.chain_params = :signet
require 'money'
Money.rounding_mode = BigDecimal::ROUND_HALF_UP
Money.locale_backend = nil
require 'net/http'
require 'wif_file'
require 'types'

class InsufficientFundsError < RuntimeError; end

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
    wif_file.to_key
  end

  def fetch_balance
    address = load_key.to_addr
    uri = URI("https://mempool.space/signet/api/address/#{address}")
    satoshi_balance = JSON.parse(Net::HTTP.get(uri))["chain_stats"]["funded_txo_sum"]
    Money.new(satoshi_balance, 'BTC')
  end

  def build_transaction(utxos, recipient_address, amount_to_send)
    money_amount_to_send = Types::BTCMoney[amount_to_send]

    tx = Bitcoin::Tx.new

    # add inputs
    utxos.each do |utxo|
      tx.in << Bitcoin::TxIn.new(
        out_point: Bitcoin::OutPoint.from_txid(utxo['txid'], utxo['vout'])
      )
    end

    # add outputs
    fee = miner_fee(input_count: utxos.size, output_count: 2)
    current_balance = utxos.sum { |utxo| Money.new(utxo['value'], 'BTC') }
    change_amount = current_balance - money_amount_to_send - fee
    if change_amount < Money.new(0, 'BTC')
      raise InsufficientFundsError, "Sending #{money_amount_to_send.format} with fee #{fee.format} exceeds available amount #{current_balance.format}"
    end
    tx.out << Bitcoin::TxOut.new(value: money_amount_to_send, script_pubkey: Bitcoin::Script.parse_from_addr(recipient_address))
    tx.out << Bitcoin::TxOut.new(value: change_amount, script_pubkey: Bitcoin::Script.parse_from_addr(load_key.to_addr))

    tx
  end

  def estimate_tx_vbytes(input_count:, output_count:)
    base_tx_size = 10
    base_tx_size + (input_count * 68) + (output_count * 31)
  end

  def fetch_recommended_fee_rate
    uri = URI("https://mempool.space/signet/api/v1/fees/recommended")
    raw_response = Net::HTTP.get(uri)
    response_data = JSON.parse(raw_response)
    Money.new(response_data["hourFee"], "BTC")
  end

  def miner_fee(input_count:, output_count:)
    fetch_recommended_fee_rate * estimate_tx_vbytes(input_count:, output_count:)
  end
end
