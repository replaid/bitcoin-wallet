require 'fileutils'

class Wallet
  KEY_FILENAME = 'wallet.key'

  def ensure_key_file(directory = Dir.pwd)
    # Ensure the directory exists before proceeding
    Dir.mkdir(directory) unless Dir.exist?(directory)

    filename = File.join(directory, KEY_FILENAME)
    return if File.exist?(filename)  # Don't overwrite existing file

    FileUtils.touch(filename)
    FileUtils.chmod(0600, filename)
    key = Bitcoin::Key.generate
    File.write(filename, key.to_wif)
  rescue Errno::EACCES => e
    raise "Permission denied: #{e.message}"
  rescue Errno::ENOENT => e
    raise "Directory doesn't exist: #{e.message}"
  end

  def self.load_key
    Bitcoin::Key.from_wif(File.read(KEY_FILENAME))
  end
end
