require 'fileutils'

class WIFFile
  attr_reader :directory, :filename

  def initialize(directory: Dir.pwd, filename: 'wallet.key')
    @directory = directory
    @filename = filename
  end

  def path
    File.join(directory, filename)
  end

  def ensure_exists!
    # Ensure the directory exists before proceeding
    FileUtils.mkdir_p(directory) unless Dir.exist?(directory)

    return if File.exist?(path)  # Don't overwrite existing file

    FileUtils.touch(path)
    FileUtils.chmod(0600, path)
    key = yield
    File.write(path, key.to_wif)
  rescue Errno::EACCES => e
    raise "Permission denied: #{e.message}"
  rescue Errno::ENOENT => e
    raise "Directory doesn't exist: #{e.message}"
  end

  def to_key
    Bitcoin::Key.from_wif(File.read(path))
  end
end
