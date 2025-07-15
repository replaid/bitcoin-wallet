module Infrastructure
  class WIFFileAdapter
    attr_reader :path

    def initialize(path = nil)
      @path = path || default_path
    end

    def path=(new_path)
      raise ArgumentError, "Path cannot be nil" unless new_path
      @path = new_path
    end

    def generate
      key = Bitcoin::Key.generate
      save_key(key)
      key
    end

    private

    def save_key(key)
      File.write(@path, key.to_wif)
      File.chmod(0600, @path)
    end

    def default_path
      File.join(Dir.pwd, 'wallet.key')
    end
  end
end
