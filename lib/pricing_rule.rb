# frozen_string_literal: true

# Represents a pricing rule for a specific product.
# Note: It is assumed that a product can only have a single pricing rule.
class PricingRule
  attr_reader :product_code

  # Initializes a new PricingRule object.
  #
  # @param product_code [String] The code of the product to which the rule applies.
  # @param rule [Proc, Lambda] The rule to be applied for calculating the price.
  def initialize(product_code, rule)
    @product_code = product_code
    @rule = rule
  end

  # Applies the pricing rule to calculate the price based on the given product code and quantity.
  #
  # @param product_code [String] The code of the product.
  # @param quantity [Integer] The quantity of the product.
  # @param unit_price [Float] The unit price of the product.
  # @return [Float] The calculated price based on the pricing rule.
  # @raise [StandardError] If the given product code doesn't match the pricing_code.
  # @raise [StandardError] If the quantity is negative.
  def apply(product_code, quantity, unit_price)
    raise 'Invalid product' if product_code != @product_code
    raise 'Invalid quantity' if quantity < 1

    @rule.call(quantity, unit_price)
  end
end
