require 'wallet'
require 'bitcoin'
Bitcoin.chain_params = :signet
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
end

describe Wallet do
  let(:sample_wif) { 'cVctnY8ai1XxfKahKoBU8oUSNHCSDAmWcSwMDHYEWWrH7Ft6yXt6' }
  let(:sample_key) { instance_double(Bitcoin::Key, to_addr: 'mu8VyQWff8fPzeG466C1fjBmA7kqnhzFL2') }
  let(:wif_file) { instance_double(WIFFile, to_key: sample_key) }
  let(:wallet) { Wallet.new(wif_file: wif_file) }

  describe '#ensure_key_file' do
    before do
      expect(Bitcoin::Key).to receive(:generate).and_return(sample_key)
    end

    it 'generates a Bitcoin::Key for WIFFile#ensure_exists!' do
      expect(wif_file).to receive(:ensure_exists!) do |&block|
        expect(block.call).to be(sample_key)
      end
      wallet.ensure_key_file
    end
  end

  describe '#load_key' do
    it 'delegates to the WIFFile' do
      expect(wif_file).to receive(:to_key).and_return(sample_key)
      expect(wallet.load_key).to be(sample_key)
    end
  end

  describe 'fetches the balance of funds' do
    context 'with a newly-generated key' do
      it 'has a zero balance' do
        VCR.use_cassette('zero_balance') do
          expect(wallet.fetch_balance).to eq(Money.new(0, 'BTC'))
        end
      end
    end

    context 'with a funded key' do
      let(:funded_key) { instance_double(Bitcoin::Key, to_addr: 'mxT8fcbjy53gCm1us3igBZ9fSvA52uQSNf') }
      let(:sample_key) { funded_key }

      it 'has the funded balance' do
        VCR.use_cassette('funded_balance') do
          expect(wallet.fetch_balance).to eq(Money.new(331388, 'BTC'))
        end
      end
    end
  end

  describe '#build_transaction' do
    let(:utxos) do
      [{"txid" => "abc123", "vout" => 0, "value" => 100_000}]
    end
    let(:amount_to_send) { Money.new(50_000, 'BTC') }
    let(:recipient_address) { 'mzGAKzEfQ4qr31pn9byp71rTfQzyAEBVz3' }

    it "includes all UTXOs as inputs" do
      VCR.use_cassette('recommended_fee_rate') do
        tx = wallet.build_transaction(utxos, recipient_address, Money.new(50_000, 'BTC'))
        expect(tx.inputs.size).to eq(1)
        expect(tx.inputs.first.out_point.txid).to eq("abc123")
      end
    end

    it "calculates change correctly" do
      expected_fee = nil
      VCR.use_cassette('recommended_fee_rate') do
        expected_fee = wallet.miner_fee(input_count: utxos.size, output_count: 2)
      end
      VCR.use_cassette('recommended_fee_rate') do
        amount_to_send = Money.new(50_000, 'BTC')
        tx = wallet.build_transaction(utxos, recipient_address, amount_to_send)
        expect(tx.outputs.last.value).to eq(Money.new(100_000, 'BTC') - amount_to_send - expected_fee)
      end
    end

    it 'raises an error if amount_to_send is not a Money object' do
      integer_amount = 50_000
      expect { wallet.build_transaction(utxos, recipient_address, integer_amount) }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'raises InsufficientFundsError when balance < amount + fee' do
      large_amount = amount_to_send * 100
      VCR.use_cassette('recommended_fee_rate') do
        expect { wallet.build_transaction(utxos, recipient_address, large_amount) }
          .to raise_error(InsufficientFundsError)
      end
    end

    it 'includes exactly one change output when inputs exceed amount + fee' do
      small_amount = amount_to_send / 4
      tx = nil
      VCR.use_cassette('recommended_fee_rate') do
        tx = wallet.build_transaction(utxos, recipient_address, small_amount)
      end
      wallet_address = wallet.load_key.to_addr
      # Convert both to address strings for comparison
      output_addresses = tx.outputs.map { |o| o.script_pubkey.to_addr }

      expect(output_addresses).to include(wallet_address)
      expect(output_addresses.grep(wallet_address).size).to eq(1)
    end
  end

  describe '#estimate_tx_vbytes' do
    it 'assumes 68 vbytes for SegWit inputs, 31 for outputs' do
      expect(wallet.estimate_tx_vbytes(input_count: 1, output_count: 2)).to eq(140)
    end
  end

  describe '#fetch_recommended_fee_rate' do
    it 'returns a Money amount' do
      VCR.use_cassette('recommended_fee_rate') do
        expect(wallet.fetch_recommended_fee_rate).to eq(Money.new(1, 'BTC'))
      end
    end
  end

  describe '#miner_fee' do
    it 'calculates correctly' do
      VCR.use_cassette('recommended_fee_rate') do
        expect(wallet.miner_fee(input_count: 4, output_count: 2)).to eq(Money.new(344, 'BTC'))
      end
    end
  end
end
