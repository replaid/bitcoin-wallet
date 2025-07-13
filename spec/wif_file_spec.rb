require 'securerandom'
require 'tmpdir'

describe WIFFile do
  def inside_tmpdir
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        yield dir
      end
    end
  end

  let(:sample_wif) { 'cVctnY8ai1XxfKahKoBU8oUSNHCSDAmWcSwMDHYEWWrH7Ft6yXt6' }
  let(:sample_key) { instance_double(Bitcoin::Key, to_wif: sample_wif) }

  describe '#directory' do
    it 'is current working directory by default' do
      inside_tmpdir do |dir|
        file = WIFFile.new
        expect(file.directory).to eq(File.realpath(dir))
      end
    end

    it 'can be overridden' do
      file = WIFFile.new(directory: 'some_other_dir')
      expect(file.directory).to eq('some_other_dir')
    end
  end

  describe '#filename' do
    it 'is "wallet.key" by default' do
      file = WIFFile.new
      expect(file.filename).to eq('wallet.key')
    end

    it 'can be overridden' do
      file = WIFFile.new(filename: 'foo.bar')
      expect(file.filename).to eq('foo.bar')
    end
  end

  describe '#ensure_exists!' do
    it 'has user-only permissions' do
      inside_tmpdir do |dir|
        WIFFile.new.ensure_exists! do
          sample_key
        end

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

        WIFFile.new.ensure_exists! do
          sample_key
        end
        expect(File.read(filename)).to eq(original_content)
      end
    end

    it 'creates the directory if missing' do
      inside_tmpdir do |dir|
        new_dir = File.join(dir, 'new_parent_dir/new_directory')
        WIFFile.new(directory: new_dir).ensure_exists! do
          sample_key
        end
        expect(Dir.exist?(new_dir)).to be true
        filename = File.join(new_dir, 'wallet.key')
        expect(File.exist?(filename)).to be true
      end
    end

    it 'writes to the file with the result of the block' do
      my_key = sample_key
      file_contents = nil
      wif_file = nil
      inside_tmpdir do |dir|
        wif_file = WIFFile.new
        wif_file.ensure_exists! do
          my_key
        end
        file_contents = File.read(wif_file.filename)
      end
      expect(file_contents).to eq(sample_wif)
    end
  end

  describe '#to_key' do
    it 'returns a key' do
      inside_tmpdir do |dir|
        wif_file = WIFFile.new
        wif_file.ensure_exists! do
          sample_key
        end
        new_key = WIFFile.new.to_key
        expect(new_key).to be_a(Bitcoin::Key)
      end
    end
  end

end
