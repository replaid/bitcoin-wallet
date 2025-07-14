require 'dry/types'

module Types
  include Dry.Types()

  BTCMoney = Instance(::Money).constructor do |value|
    unless value.is_a?(::Money)
      raise Dry::Types::ConstraintError.new("Must be a Money object", value)
    end
    unless value.currency.iso_code == 'BTC'
      raise Dry::Types::ConstraintError.new("Currency must be BTC", value)
    end
    value
  end
end
