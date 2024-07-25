# frozen_string_literal: true

# Represents a product in the supermarket.
class Product
  attr_reader :code, :name, :price

  # Initializes a new instance of the Product class.
  #
  # @param code [String] The code of the product.
  # @param name [String] The name of the product.
  # @param price [BigDecimal] The price of the product.
  def initialize(code, name, price)
    @code = code
    @name = name
    @price = price
  end
end
