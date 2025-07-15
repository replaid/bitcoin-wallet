# spec/infrastructure/wif_file_adapter_spec.rb
require 'spec_helper'
require 'fileutils'

module Infrastructure
  RSpec.describe WIFFileAdapter do
    let(:temp_dir) { Dir.mktmpdir('wallet_test') }
    let(:new_path) { File.join(temp_dir, 'new_wallet.key') }

    before { Dir.mkdir(temp_dir) unless Dir.exist?(temp_dir) }
    after { FileUtils.remove_entry(temp_dir) }

    describe '#path=' do
      it 'changes the storage location' do
        adapter = described_class.new
        adapter.path = new_path
        expect(adapter.instance_variable_get(:@path)).to eq(new_path)
      end

      it 'persists keys to the new location' do
        adapter = described_class.new
        adapter.path = new_path
        key = adapter.generate

        expect(File.exist?(new_path)).to be true
        expect(File.read(new_path)).to eq(key.to_wif)
      end
    end
  end
end
