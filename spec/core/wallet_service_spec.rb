require 'spec_helper'

module Core
  module Services
    RSpec.describe WalletService do
      include Dry::Monads[:result]

      let(:mempool_adapter) { instance_double(Infrastructure::MempoolSpaceAdapter) }
      let(:key_store) { instance_double(Infrastructure::WIFFileAdapter) }
      let(:service) { described_class.new(mempool: mempool_adapter, key_store: key_store) }

      describe '#get_balance' do
        let(:utxo_values) { [100_000, 50_000] }
        let(:utxos) { utxo_values.map { |v| Core::Entities::UTXO.new(value: v, txid: 'txid', vout: 0) } }

        it 'returns sum of UTXO values as Money' do
          allow(mempool_adapter).to receive(:get_utxos)
            .with('test_address')
            .and_return(Success(utxos))

          result = service.get_balance('test_address')

          aggregate_failures do
            expect(result).to be_success
            expect(result.value!).to be_a(Money)
            expect(result.value!.currency).to eq('BTC')
            expect(result.value!.fractional).to eq(150_000)
          end
        end

        context 'when adapter fails' do
          it 'returns failure with api_error' do
            allow(mempool_adapter).to receive(:get_utxos)
              .with('test_address')
              .and_return(Failure(:api_error))

            result = service.get_balance('test_address')
            expect(result).to be_failure
          end
        end
      end

      describe '#generate_address' do
        let(:test_key) { Bitcoin::Key.generate }
        let(:key_store) { Infrastructure::WIFFileAdapter.new }
        let(:service) { described_class.new(mempool: mempool_adapter, key_store: key_store) }

        it 'returns a new key' do
          allow(key_store).to receive(:generate).and_return(test_key)
          expect(service.generate_address).to eq(test_key)
        end
      end
    end
  end
end
