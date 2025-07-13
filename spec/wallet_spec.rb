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

  it 'has no need for inside_tmpdir and possible other file related warts'

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
  end
end
