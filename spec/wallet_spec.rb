require 'wallet'

include Bitcoin::Opcodes

describe Wallet do
  let(:old_sample_wif) { 'cVctnY8ai1XxfKahKoBU8oUSNHCSDAmWcSwMDHYEWWrH7Ft6yXt6' }
  let(:old_sample_key) { instance_double(Bitcoin::Key, to_addr: 'mu8VyQWff8fPzeG466C1fjBmA7kqnhzFL2') }
  let(:unfunded_key) {
    instance_double(
      SegWitKey,
      address: 'tb1qqdyfx8fg7mecnyz5q2v933myftadzejjznydvk6fjvu95j5dj40l2fe4pvu',
      legacy_address: 'n45MssfR7W2QQhRbwWzkjnYhckX9Ut96bV',
      bitcoin_key: Bitcoin::Key.new(
        priv_key: '9b0660db724abec0977cc4bdcd42069d28294e61e8991701fa8c0c22377467fb',
        pubkey: '0348931d28f6f3899054029858c7644afad1665214c8d65b4993385a4a8d955ff5',
        key_type: Bitcoin::Key::TYPES[:compressed]
      )
    )
  }
  let(:funded_key) {
    instance_double(
      SegWitKey,
      legacy_address: 'mxT8fcbjy53gCm1us3igBZ9fSvA52uQSNf',
      address: 'tb1qqfk8rkavnw8gdgqyyzgkuvy60aug8xgdqjundk5m7yy4wnm6jzpf5p2w340'
    )
  }
  let(:sample_segwit_key) { unfunded_key }
  let(:wif_file) { instance_double(WIFFile, to_key: sample_segwit_key) }
  let(:wallet) { Wallet.new(wif_file: wif_file) }

  describe '#ensure_key_file' do
    before do
      expect(Bitcoin::Key).to receive(:generate).and_return(sample_segwit_key)
    end

    it 'generates a Bitcoin::Key for WIFFile#ensure_exists!' do
      expect(wif_file).to receive(:ensure_exists!) do |&block|
        expect(block.call).to be(sample_segwit_key)
      end
      wallet.ensure_key_file
    end
  end

  describe '#load_key' do
    it 'delegates to the WIFFile' do
      expect(wif_file).to receive(:to_key).and_return(sample_segwit_key)
      expect(wallet.load_key).to be(sample_segwit_key)
    end
  end

  describe 'fetches the balance of funds' do
    context 'with a newly-generated key' do
      it 'has a zero balance' do
        VCR.use_cassette('zero_balance') do
          expect(wallet.fetch_balance).to eq(Money.new(0, 'BTC'))
        end
      end
    end

    context 'with a funded key' do
      let(:sample_segwit_key) { funded_key }

      it 'has the funded balance' do
        VCR.use_cassette('funded_balance') do
          expect(wallet.fetch_balance).to eq(Money.new(331388, 'BTC'))
        end
      end
    end
  end

  describe 'transactions' do
    let(:recipient_address) { 'mzGAKzEfQ4qr31pn9byp71rTfQzyAEBVz3' }
    let(:amount_to_send) { Money.new(50_000, 'BTC') }
    let(:utxos) do
      [{"txid" => "abc123", "vout" => 0, "value" => 100_000}]
    end

    describe '#build_transaction' do

      it "includes all UTXOs as inputs" do
        VCR.use_cassette('recommended_fee_rate') do
          tx = wallet.build_transaction(utxos, recipient_address, Money.new(50_000, 'BTC'))
          expect(tx.inputs.size).to eq(1)
          expect(tx.inputs.first.out_point.txid).to eq("abc123")
        end
      end

      it "calculates change correctly" do
        expected_fee = nil
        VCR.use_cassette('recommended_fee_rate') do
          expected_fee = wallet.miner_fee(input_count: utxos.size, output_count: 2)
        end
        VCR.use_cassette('recommended_fee_rate') do
          tx = wallet.build_transaction(utxos, recipient_address, amount_to_send)
          expect(tx.outputs.last.value).to eq((Money.new(100_000, 'BTC') - amount_to_send - expected_fee).fractional)
        end
      end

      it 'raises an error if amount_to_send is not a Money object' do
        integer_amount = 50_000
        expect { wallet.build_transaction(utxos, recipient_address, integer_amount) }.to raise_error(Dry::Types::ConstraintError)
      end

      it 'raises InsufficientFundsError when balance < amount + fee' do
        large_amount = amount_to_send * 100
        VCR.use_cassette('recommended_fee_rate') do
          expect { wallet.build_transaction(utxos, recipient_address, large_amount) }
            .to raise_error(InsufficientFundsError)
        end
      end

      it 'includes exactly one change output when inputs exceed amount + fee' do
        small_amount = amount_to_send / 4
        tx = nil
        VCR.use_cassette('recommended_fee_rate') do
          tx = wallet.build_transaction(utxos, recipient_address, small_amount)
        end
        wallet_address = wallet.legacy_address
        # Convert both to address strings for comparison
        output_addresses = tx.outputs.map { |o| o.script_pubkey.to_addr }

        expect(output_addresses).to include(wallet_address)
        expect(output_addresses.grep(wallet_address).size).to eq(1)
      end
    end

    describe '#sign_transaction' do
      let(:sample_segwit_key) { funded_key }
      before do
        allow(sample_segwit_key).to receive(:bitcoin_key).and_return(
          Bitcoin::Key.new(
            priv_key: 'b1eb445c19a27c9dec30563d86cc777b288f3e1f32b797135dfebe3aa021a370',
            pubkey: '026c71dbac9b8e86a00420916e309a7f7883990d04b936da9bf109574f7a90829a',
            key_type: Bitcoin::Key::TYPES[:compressed]
          )
        )
      end
      let(:unsigned_tx) do
        VCR.use_cassette('recommended_fee_rate') do
          wallet.build_transaction(utxos, recipient_address, amount_to_send)
        end
      end

      context 'with real funded UTXOs' do
        it 'successfully signs transactions' do
          # Get actual UTXOs from blockchain
          utxos = nil
          VCR.use_cassette('signet_utxos') do
            uri = URI("https://mempool.space/signet/api/address/#{wallet.legacy_address}/utxo")
            utxos = JSON.parse(Net::HTTP.get(uri))
          end

          # Enrich each UTXO with scriptPubKey
          utxos.each do |utxo|
            VCR.use_cassette("signet_tx_#{utxo['txid']}") do
              tx_data = JSON.parse(Net::HTTP.get(URI("https://mempool.space/signet/api/tx/#{utxo['txid']}")))
              utxo['scriptPubKey'] = tx_data['vout'][utxo['vout']]['scriptpubkey']
            end
          end

          # Build and sign real transaction
          tx = nil
          VCR.use_cassette('signet_tx_build') do
            tx = wallet.build_transaction(utxos, recipient_address, amount_to_send)
          end

          signed_tx = nil
          VCR.use_cassette('signet_tx_sign') do
            signed_tx = wallet.sign_transaction(tx)
          end

          # Verify signature validity against actual blockchain data
          expect(signed_tx.inputs.first.script_sig.chunks.size).to eq(2)

          spent_input = signed_tx.inputs.first
          spent_utxo = utxos.find { |u|
            u['txid'] == spent_input.out_point.txid &&
            u['vout'] == spent_input.out_point.index
          }
          script_pubkey = Bitcoin::Script.parse_from_payload(spent_utxo['scriptPubKey'].htb)

          verification_result = signed_tx.verify_input_sig(0, script_pubkey)
          expect(verification_result).to be true
        end

        it 'raises SigningError when attempting to sign non-wallet UTXOs' do
          # Mock the UTXO lookup to avoid network calls
          allow(wallet).to receive(:find_utxo_for_input).and_return({
            'txid' => 'abc123',
            'vout' => 0,
            'scriptPubKey' => Bitcoin::Script.to_p2pkh(Bitcoin.hash160(Bitcoin::Key.generate.pubkey)).to_hex,
            'value' => 100000
          })

          foreign_utxo = build_foreign_utxo(address: unfunded_key.legacy_address)
          tx_with_foreign_input = nil
          VCR.use_cassette('recommended_fee_rate') do
            tx_with_foreign_input = wallet.build_transaction([foreign_utxo], recipient_address, amount_to_send)
          end

          expect { wallet.sign_transaction(tx_with_foreign_input) }
            .to raise_error(SigningError)
        end
      end
    end
  end

  describe '#estimate_tx_vbytes' do
    it 'assumes 68 vbytes for SegWit inputs, 31 for outputs' do
      expect(wallet.estimate_tx_vbytes(input_count: 1, output_count: 2)).to eq(140)
    end
  end

  describe '#fetch_recommended_fee_rate' do
    it 'returns a Money amount' do
      VCR.use_cassette('recommended_fee_rate') do
        expect(wallet.fetch_recommended_fee_rate).to eq(Money.new(1, 'BTC'))
      end
    end
  end

  describe '#miner_fee' do
    it 'calculates correctly' do
      VCR.use_cassette('recommended_fee_rate') do
        expect(wallet.miner_fee(input_count: 4, output_count: 2)).to eq(Money.new(344, 'BTC'))
      end
    end
  end

  describe '#broadcast_transaction' do
    let(:sample_tx) do
      tx = Bitcoin::Tx.new
      tx.version = 1
      tx.lock_time = 0

      input = Bitcoin::TxIn.new
      input.out_point = Bitcoin::OutPoint.new('00' * 32, 0xffffffff)
      input.script_sig = Bitcoin::Script.new << OP_0 << OP_0
      tx.inputs << input

      output = Bitcoin::TxOut.new
      output.value = 1000
      output.script_pubkey = Bitcoin::Script.parse_from_addr(wallet.legacy_address)
      tx.outputs << output

      tx
    end

    context 'when broadcast is successful' do
      it 'returns the transaction ID' do
        stub_request(:post, "https://mempool.space/signet/api/tx")
          .to_return(
            status: 200,
            body: { txid: sample_tx.txid }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        expect(wallet.broadcast_transaction(sample_tx)).to eq(sample_tx.txid)
      end
    end

    context 'when broadcast fails' do
      it 'raises an error for invalid transactions' do
        stub_request(:post, "https://mempool.space/signet/api/tx")
          .to_return(
            status: 400,
            body: { message: "Transaction rejected: mandatory-script-verify-flag-failed" }.to_json
          )

        expect { wallet.broadcast_transaction(sample_tx) }
          .to raise_error(SigningError, /Invalid transaction/)
      end

      it 'raises an error for rejected transactions' do
        stub_request(:post, "https://mempool.space/signet/api/tx")
          .to_return(
            status: 403,
            body: { message: "Transaction already in blockchain" }.to_json
          )

        expect { wallet.broadcast_transaction(sample_tx) }
          .to raise_error(SigningError, /Transaction rejected/)
      end

      it 'raises an error for rate limiting' do
        stub_request(:post, "https://mempool.space/signet/api/tx")
          .to_return(
            status: 429,
            body: { message: "Too many requests" }.to_json
          )

        expect { wallet.broadcast_transaction(sample_tx) }
          .to raise_error(SigningError, /Rate limited/)
      end
    end
  end
end
