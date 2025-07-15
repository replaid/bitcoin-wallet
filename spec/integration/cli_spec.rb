require 'spec_helper'

RSpec.describe 'CLI Integration' do
  let(:cli) { File.expand_path('../../bin/wallet_cli.rb', __dir__) }
  let(:data_dir) { File.expand_path('../tmp/test_data', __dir__) }

  before do
    FileUtils.rm_rf(data_dir)
    FileUtils.mkdir_p(data_dir)

    # Generate test key programmatically
    test_key = Bitcoin::Key.generate
    wallet_path = File.join(data_dir, 'wallet.key')
    File.write(wallet_path, test_key.to_wif)
    File.chmod(0600, File.join(data_dir, 'wallet.key'))
  end

  after do
    FileUtils.rm_rf(data_dir)
  end

  it 'runs balance command successfully' do
    output = `DATA_DIR=#{data_dir} ruby #{cli} balance 2>&1`

    if $?.success?
      expect(output).to include('Current balance:')
    else
      puts "CLI failed with output: #{output}"
      expect(output).to include('Current balance:') # This will fail but show the actual error
    end
  end
end
