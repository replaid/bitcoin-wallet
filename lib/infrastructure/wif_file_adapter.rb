module Infrastructure
  class WifFileAdapter
    def initialize(path = 'wallet.key')
      @path = path
    end

    def load
      return nil unless File.exist?(@path)
      Bitcoin::Key.from_wif(File.read(@path))
    end

    def generate
      key = Bitcoin::Key.generate
      File.write(@path, key.to_wif)
      key
    end
  end
end
