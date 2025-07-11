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
  def inside_tmpdir
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        yield dir
      end
    end
  end

  describe 'creating the key' do
    it 'has user-only permissions' do
      inside_tmpdir do |dir|
        Wallet.new.ensure_key_file
        filename = 'wallet.key'
        expect(File.exist?(filename)).to be true

        file_stat = File.stat(filename)
        permission_bits = file_stat.mode & 0777
        expect(permission_bits).to eq(0600)
      end
    end

    it 'does not overwrite existing key file' do
      inside_tmpdir do |dir|
        filename = 'wallet.key'
        FileUtils.touch(filename)
        FileUtils.chmod(0600, filename)
        File.write(filename, 'existing')
        expect(File.exist?(filename)).to be true

        original_content = File.read(filename)
        Wallet.new.ensure_key_file
        expect(File.read(filename)).to eq(original_content)
      end
    end

    it 'creates the directory if missing' do
      inside_tmpdir do |dir|
        new_dir = File.join(dir, 'new_parent_dir/new_directory')
        Wallet.new.ensure_key_file(new_dir)
        expect(Dir.exist?(new_dir)).to be true
        filename = File.join(new_dir, 'wallet.key')
        expect(File.exist?(filename)).to be true
      end
    end

    it 'creates a key with default properties' do
      key = nil
      inside_tmpdir do |dir|
        Wallet.new.ensure_key_file
        key = Wallet.load_key
      end
      expect(key.priv_key.size).to eq(64)
      expect(key.pubkey.size).to eq(66)
      expect(key.compressed?).to be true
    end
  end

  describe 'loading the key' do
    it 'returns a key' do
      inside_tmpdir do |dir|
        existing_key = Bitcoin::Key.generate
        filename = File.join(dir, 'wallet.key')
        FileUtils.touch(filename)
        FileUtils.chmod(0600, filename)
        File.write(filename, existing_key.to_wif)
        new_key = Wallet.load_key
        expect(new_key).to be_a(Bitcoin::Key)
      end
    end
  end

  describe 'fetches the balance of funds' do
    context 'with a newly-generated key' do
      let(:wif) { 'cVctnY8ai1XxfKahKoBU8oUSNHCSDAmWcSwMDHYEWWrH7Ft6yXt6' }
      let(:key) { Bitcoin::Key.from_wif(wif) }
      let(:wallet) {
        filename = 'wallet.key'
        FileUtils.touch(filename)
        FileUtils.chmod(0600, filename)
        File.write(filename, wif)
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
