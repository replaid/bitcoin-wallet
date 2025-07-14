require 'segwit_key'

describe SegWitKey do
  let(:valid_bitcoin_key) {
    Bitcoin::Key.new(
      priv_key: '9b0660db724abec0977cc4bdcd42069d28294e61e8991701fa8c0c22377467fb',
      pubkey: '0348931d28f6f3899054029858c7644afad1665214c8d65b4993385a4a8d955ff5'
    )
  }

  it 'must be initialized with a Bitcoin::Key' do
    expect { SegWitKey.new(bitcoin_key: 'value that is not a Bitcoin::Key', network: :signet) }.to raise_error(Dry::Types::ConstraintError)
  end

  it 'must be initialized with a network option' do
    expect { SegWitKey.new(bitcoin_key: valid_bitcoin_key) }.to raise_error(KeyError)
  end

  it 'can be initialized successfully' do
    my_bk = Bitcoin::Key.new(
      priv_key: '9b0660db724abec0977cc4bdcd42069d28294e61e8991701fa8c0c22377467fb',
      pubkey: '0348931d28f6f3899054029858c7644afad1665214c8d65b4993385a4a8d955ff5'
    )
    SegWitKey.new(bitcoin_key: my_bk, network: :signet)
    expect { SegWitKey.new(bitcoin_key: valid_bitcoin_key, network: :signet) }.not_to raise_error
  end
end

