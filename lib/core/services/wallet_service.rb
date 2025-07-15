module Core
  module Services
    class WalletService
      include Dry::Monads[:result]

      def initialize(mempool:, key_store:)
        @mempool = mempool
        @key_store = key_store
      end

      def get_balance(address)
        @mempool.get_utxos(address)
          .bind { |utxos| calculate_balance(utxos) }
      end

      def generate_address
        @key_store.generate
      end

      private

      def calculate_balance(utxos)
        total = utxos.sum(&:value)
        Success(Money.new(total, 'BTC'))
      end
    end
  end
end
