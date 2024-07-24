class PricingRule
  attr_reader :product_code

  def initialize(product_code, rule)
    @product_code = product_code
    @rule = rule # Proc or lambda
  end

  def apply(product_code, quantity)
    raise 'Invalid product' if product_code != @product_code
    raise 'Invalid quantity' if quantity.negative?

    @rule.call(quantity)
  end
end
