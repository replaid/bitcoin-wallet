require 'wallet'
require 'tmpdir'

describe Wallet do
  describe 'creating the key' do
    it 'has user-only permissions' do
      Dir.mktmpdir do |dir|
        Wallet.new.ensure_key_file(dir)
        filename = File.join(dir, 'wallet.key')
        expect(File.exist?(filename)).to be true

        file_stat = File.stat(filename)
        permission_bits = file_stat.mode & 0777
        expect(permission_bits).to eq(0600)
      end
    end

    it 'does not overwrite existing key file' do
      Dir.mktmpdir do |dir|
        filename = File.join(dir, 'wallet.key')
        FileUtils.touch(filename)
        FileUtils.chmod(0600, filename)
        File.write(filename, 'existing')
        expect(File.exist?(filename)).to be true

        original_content = File.read(filename)
        Wallet.new.ensure_key_file(dir)
        expect(File.read(filename)).to eq(original_content)
      end
    end

    it 'creates the directory if missing' do
      Dir.mktmpdir do |dir|
        new_dir = File.join(dir, 'new_directory')
        Wallet.new.ensure_key_file(new_dir)
        expect(Dir.exist?(new_dir)).to be true
        filename = File.join(new_dir, 'wallet.key')
        expect(File.exist?(filename)).to be true
      end
    end
  end
end
