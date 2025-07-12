describe WIFFile do
  describe '#directory' do
    def inside_tmpdir
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          yield dir
        end
      end
    end

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
end
