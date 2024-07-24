class Checkout
  def initialize(pricing_rules)
    @pricing_rules = pricing_rules
    @basket = []
  end

  def scan(product)
    @basket << product
  end

  def total
    return 0 if @basket.empty?

    basket_summary.sum do |product_summary|
      product_code = product_summary[:product_code]
      quantity = product_summary[:quantity]
      unit_price = product_summary[:price]

      calculate_subtotal(product_code, quantity, unit_price)
    end
  end

  private

  # Returns an array of hashes with product code, total quantity present in basket and unit price
  def basket_summary
    @basket.group_by(&:code).map do |product_code, products|
      { product_code:, quantity: products.size, price: products.first.price }
    end
  end

  def pricing_rule_for_product(product_code)
    @pricing_rules.find { |pricing_rule| pricing_rule.product_code == product_code }
  end

  def calculate_subtotal(product_code, quantity, unit_price)
    pricing_rule_for_product = pricing_rule_for_product(product_code)

    if pricing_rule_for_product
      pricing_rule_for_product.apply(product_code, quantity)
    else
      quantity * unit_price
    end
  end
end
