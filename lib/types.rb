require 'dry/types'
require 'bitcoin'
require 'money'

module Types
  include Dry.Types()

  BitcoinKey = Instance(::Bitcoin::Key)

  BTCMoney = Instance(::Money).constructor do |value|
    raise Dry::Types::ConstraintError.new("Must be a Money object", value) unless value.is_a?(::Money)
    raise Dry::Types::ConstraintError.new("Currency must be BTC", value) unless value.currency.iso_code == 'BTC'
    value
  end

  Satoshis = Integer.constrained(gteq: 0)
  TransferSatoshis = Integer.constrained(gteq: 546) # Dust limit

  Address = String.constrained(
    format: /\A([mn]|[tb]1)[a-zA-HJ-NP-Z0-9]{25,39}\z/
  )

  LegacyAddress = String.constrained(
    format: /\A[mn][1-9A-HJ-NP-Za-km-z]{25,34}\z/
  )

  SegWitAddress = String.constrained(
    format: /\A(tb1|bc1)[02-9ac-hj-np-z]{39,59}\z/
  )
end
