module Core
  module Entities
    class UTXO
      attr_reader :value, :txid, :vout

      def initialize(value:, txid:, vout:)
        @value = value
        @txid = txid
        @vout = vout
      end
    end
  end
end
