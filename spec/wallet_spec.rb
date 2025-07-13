require 'wallet'
require 'tmpdir'
require 'bitcoin'
Bitcoin.chain_params = :signet
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
end

describe Wallet do
  let(:sample_wif) { 'cVctnY8ai1XxfKahKoBU8oUSNHCSDAmWcSwMDHYEWWrH7Ft6yXt6' }
  let(:sample_key) { Bitcoin::Key.from_wif(sample_wif) }

  it 'has no need for inside_tmpdir and possible other file related warts'

  def inside_tmpdir
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        yield dir
      end
    end
  end

  describe '#ensure_key_file' do
    let(:wif_file) { instance_double(WIFFile) }
    let(:wallet) { Wallet.new(wif_file: wif_file) }
    let(:stub_key) { instance_double(Bitcoin::Key) }

    before do
      expect(Bitcoin::Key).to receive(:generate).and_return(stub_key)
    end

    it 'generates a Bitcoin::Key for WIFFile#ensure_exists!' do
      expect(wif_file).to receive(:ensure_exists!) do |&block|
        expect(block.call).to be(stub_key)
      end
      wallet.ensure_key_file
    end
  end

  describe 'loading the key' do
    it 'returns a key' do
      inside_tmpdir do |dir|
        filename = File.join(dir, 'wallet.key')
        FileUtils.touch(filename)
        FileUtils.chmod(0600, filename)
        File.write(filename, sample_wif)
        new_key = Wallet.new.load_key
        expect(new_key).to be_a(Bitcoin::Key)
      end
    end
  end

  describe 'fetches the balance of funds' do
    context 'with a newly-generated key' do
      let(:wallet) {
        filename = 'wallet.key'
        FileUtils.touch(filename)
        FileUtils.chmod(0600, filename)
        File.write(filename, sample_wif)
        Wallet.new
      }

      it 'has a zero balance' do
        VCR.use_cassette('zero_balance') do
          expect(wallet.fetch_balance).to eq(Money.new(0, 'BTC'))
        end
      end
    end
  end
end
