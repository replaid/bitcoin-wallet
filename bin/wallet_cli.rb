#!/usr/bin/env ruby
require 'bundler/setup'
require_relative '../system/container'

# Initialize container (remove .start if using dry-system)
Container.finalize! if Container.respond_to?(:finalize!)

# Configure data directory
data_dir = ENV['DATA_DIR'] || File.join(__dir__, '..', 'data')
Dir.mkdir(data_dir) unless Dir.exist?(data_dir)

# Get key_store from container
key_store = Container['key_store']

# Configure path if supported
if key_store.respond_to?(:path=)
  key_store.path = File.join(data_dir, 'wallet.key')
else
  warn "Warning: Key store doesn't support path configuration" if ENV['DEBUG']
end

# Initialize wallet through container
wallet = Container['wallet']

def display_help
  puts <<~HELP
    Bitcoin Signet Wallet CLI
    Commands:
      balance       - Show current balance
      send <amount> <address> - Send funds to address
      help         - Show this help
  HELP
end

begin
  wallet.ensure_key_file

  case ARGV[0]
  when 'balance'
    balance = wallet.fetch_balance
    puts "Current balance: #{balance.format}"
    puts "Address: #{wallet.legacy_address}"

  when 'send'
    amount = ARGV[1]
    address = ARGV[2]

    unless amount && address
      puts "Usage: send <amount> <address>"
      exit 1
    end

    begin
      # Convert amount to satoshis using Money conversion
      amount_btc = Money.from_amount(amount.to_f, 'BTC')

      # Get UTXOs
      utxos = wallet.mempool_api_get("/address/#{wallet.legacy_address}/utxo")

      # Build transaction
      tx = wallet.build_transaction(utxos, address, amount_btc)

      # Sign and broadcast
      signed_tx = wallet.sign_transaction(tx)
      txid = wallet.broadcast_transaction(signed_tx)

      puts "Transaction broadcasted!"
      puts "TXID: #{txid}"
      puts "View: https://mempool.space/signet/tx/#{txid}"
    rescue => e
      puts "Error: #{e.message}"
      exit 1
    end

  when 'help', nil
    display_help
  else
    puts "Unknown command: #{ARGV[0]}"
    display_help
    exit 1
  end
rescue => e
  puts "Fatal error: #{e.message}"
  pp e.backtrace
  exit 1
end
