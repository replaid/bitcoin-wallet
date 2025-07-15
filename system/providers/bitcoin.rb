Container.register_provider(:bitcoin) do
  prepare do
    require 'bitcoin'
    Bitcoin.chain_params = :signet
  end
end
