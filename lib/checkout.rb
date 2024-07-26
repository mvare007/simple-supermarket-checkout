# frozen_string_literal: true

# Represents a checkout system that can scan products and calculate the total price of all products in the basket.
class Checkout
  # The precision to be used when rounding the total price.
  #
  # @constant [Integer]
  # @return [Integer] The number of decimal places to round to when calculating the total price.
  PRECISION = 2

  # Initializes a new instance of the Checkout class.
  #
  # @param pricing_rules [Array<PricingRule>] An array of pricing rules to be applied during checkout.
  def initialize(pricing_rules)
    @pricing_rules = pricing_rules
    @basket = []
  end

  # Adds a product to the basket.
  #
  # @param product [Product] The product to be added to the basket.
  # @raise [ArgumentError] If the given product is not an instance of Product.
  def scan(product)
    raise ArgumentError, 'Invalid product' unless product.is_a?(Product)

    @basket << product
  end

  # Calculates the total price of all products in the basket, taking into acount any pricing rules.
  #
  # @return [Float] The total price of all products in the basket.
  def total
    return 0 if @basket.empty?

    total = basket_summary.sum do |product_summary|
      product_code = product_summary[:product_code]
      quantity = product_summary[:quantity]
      unit_price = product_summary[:price]

      calculate_subtotal(product_code, quantity, unit_price)
    end

    BigDecimal(total.to_s).round(PRECISION)
  end

  private

  # Returns an array of hashes with product code, total quantity present in et, and unit price.
  #
  # @return [Array<Hash>] An array of hashes representing the summary of products in the basket.
  def basket_summary
    @basket.group_by(&:code).map do |product_code, products|
      { product_code:, quantity: products.size, price: products.first.price }
    end
  end

  # Retrieves the pricing rule for a given product code.
  #
  # @param product_code [String] The product code for which to retrieve the pricing rule.
  # @return [PricingRule, nil] The pricing rule object if found, nil otherwise.
  def pricing_rule_for_product(product_code)
    @pricing_rules.find { |pricing_rule| pricing_rule.product_code == product_code }
  end

  # Calculates the subtotal for a given product based on it's pr'icing rule (if it' it'ss applicable) or unit price.
  #
  # @param product_code [String] The product code for which to calculate the subtotal.
  # @param quantity [Integer] The quantity of the product in the basket.
  # @param unit_price [BigDecimal] The unit price of the product.
  # @return [BigDecimal] The subtotal for the given product.
  def calculate_subtotal(product_code, quantity, unit_price)
    pricing_rule_for_product = pricing_rule_for_product(product_code)

    if pricing_rule_for_product
      pricing_rule_for_product.apply(product_code, quantity, unit_price)
    else
      quantity * unit_price
    end
  end
end
