require 'bitcoin'
require 'money'
require 'net/http'

require_relative 'infrastructure/wif_file_adapter'
require_relative 'core/services/wallet_service'

class InsufficientFundsError < RuntimeError; end
class SigningError < RuntimeError; end

class Wallet
  attr_reader :wif_file

  def initialize(wif_file:)
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

  def address
    load_key.address
  end

  def legacy_address
    load_key.legacy_address
  end

  def fetch_balance
    uri = URI("https://mempool.space/signet/api/address/#{legacy_address}")
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
    tx.out << Bitcoin::TxOut.new(value: money_amount_to_send.fractional, script_pubkey: Bitcoin::Script.parse_from_addr(recipient_address))
    tx.out << Bitcoin::TxOut.new(value: change_amount.fractional, script_pubkey: Bitcoin::Script.parse_from_addr(legacy_address))

    tx
  end

  def sign_transaction(tx)
    key = load_key.bitcoin_key

    tx.inputs.each_with_index do |input, index|
      utxo = find_utxo_for_input(input)

      unless owns_utxo?(utxo)
        raise SigningError, "Cannot sign foreign UTXO #{utxo['txid']}:#{utxo['vout']}"
      end

      script_pubkey = Bitcoin::Script.parse_from_payload(utxo['scriptPubKey'].htb)

      if script_pubkey.p2pkh?
        # Legacy P2PKH signing - create minimal scriptSig
        sighash = tx.sighash_for_input(index, script_pubkey, sig_version: :base)
        signature = key.sign(sighash) + [Bitcoin::SIGHASH_TYPE[:all]].pack("C")
        input.script_sig = Bitcoin::Script.new << signature << key.pubkey
      elsif script_pubkey.p2wpkh?
        # SegWit signing
        sighash = tx.sighash_for_input(index, script_pubkey, sig_version: :witness_v0)
        signature = key.sign(sighash) + [Bitcoin::SIGHASH_TYPE[:all]].pack("C")
        input.script_witness = Bitcoin::ScriptWitness.new([signature, key.pubkey.htb])
      end
    end

    tx
  end

  def mempool_api_get(endpoint)
    uri = URI("https://mempool.space/signet/api#{endpoint}")
    JSON.parse(Net::HTTP.get(uri))
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

  def broadcast_transaction(signed_tx)
    uri = URI("https://mempool.space/signet/api/tx")
    response = begin
                 Net::HTTP.post(uri, signed_tx.to_hex)
               rescue Timeout::Error, SocketError => e
                 raise SigningError, "Network error: #{e.message}"
               end

    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)["txid"]
    else
      handle_broadcast_error(response)
    end
  end

  private

  def handle_broadcast_error(response)
    error_message = begin
                      JSON.parse(response.body)["message"]
                    rescue JSON::ParserError
                      response.body
                    end

    case response.code.to_i
    when 400
      raise SigningError, "Invalid transaction: #{error_message}"
    when 403
      raise SigningError, "Transaction rejected: #{error_message}"
    when 429
      raise SigningError, "Rate limited: #{error_message}"
    else
      raise SigningError, "Broadcast failed (#{response.code}): #{error_message}"
    end
  end

  def find_utxo_for_input(input)
    txid = input.out_point.txid
    vout = input.out_point.index

    # First check if UTXO is unspent
    spend_status = mempool_api_get("/tx/#{txid}/outspend/#{vout}")
    raise SigningError, "UTXO already spent" if spend_status['spent']

    # Get full transaction details
    tx = mempool_api_get("/tx/#{txid}")
    output = tx['vout'][vout]

    {
      'txid' => txid,
      'vout' => vout,
      'value' => output['value'],
      'scriptPubKey' => output['scriptpubkey'] # Note lowercase field name
    }
  end

  def owns_utxo?(utxo)
    script = Bitcoin::Script.parse_from_payload(utxo['scriptPubKey'].htb)
    key = load_key
    our_addresses = [
      key.legacy_address, # Legacy address (m/n...)
      key.address         # SegWit address (tb1q...)
    ]
    our_addresses.include?(script.to_addr)
  end
end
