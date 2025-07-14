require 'bitcoin'
require 'securerandom'

module UTXOHelpers
  def build_foreign_utxo(value: 100_000, address:)
    {
      'txid' => SecureRandom.hex(32),  # Random transaction hash
      'vout' => rand(0..3),            # Random output index
      'value' => value,                # Satoshi amount
      'scriptPubKey' => Bitcoin::Script.parse_from_addr(address).to_hex,
      'address' => address
    }
  end
end

