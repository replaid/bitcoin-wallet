class WIFFile
  attr_reader :directory, :filename

  def initialize(directory: Dir.pwd, filename: 'wallet.key')
    @directory = directory
    @filename = filename
  end
end
