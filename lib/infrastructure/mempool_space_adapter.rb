module Infrastructure
  class MempoolSpaceAdapter
    include Dry::Monads[:result]

    API_BASE = 'https://mempool.space/signet/api'.freeze

    def get_utxos(address)
      response = Net::HTTP.get_response(URI("#{API_BASE}/address/#{address}/utxo"))
      if response.is_a?(Net::HTTPSuccess)
        Success(parse_response(response.body))
      else
        Failure(:api_error)
      end
    rescue => e
      Failure(:network_error)
    end

    private

    def parse_response(body)
      JSON.parse(body).map do |utxo|
        Core::Entities::UTXO.new(
          value: utxo['value'],
          txid: utxo['txid'],
          vout: utxo['vout']
        )
      end
    end
  end
end
