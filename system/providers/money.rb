Container.register_provider(:money) do
  prepare do
    require 'money'
    Money.rounding_mode = BigDecimal::ROUND_HALF_UP
    Money.locale_backend = nil
  end
end

