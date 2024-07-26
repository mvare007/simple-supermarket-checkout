# frozen_string_literal: true

require 'checkout'
require 'product'
require 'pricing_rule'
require 'bigdecimal'
require 'debug'

RSpec.describe Checkout do
  let(:green_tea) { Product.new('GR1', 'Green Tea', BigDecimal('3.11')) }
  let(:strawberry) { Product.new('SR1', 'Strawberry', BigDecimal('5.00')) }
  let(:coffee) { Product.new('CF1', 'Coffee', BigDecimal('11.23')) }

  let(:green_tea_pricing_rule) do
    # Buy one get one free
    PricingRule.new('GR1', ->(qty, price) { (qty / 2.0).ceil * price })
  end

  let(:strawberry_pricing_rule) do
    # Bulk discount - buy 3 or more and price drops to 4.50
    PricingRule.new('SR1', ->(qty, _price) { qty >= 3 ? qty * BigDecimal('4.50') : qty * BigDecimal('5.00') })
  end

  let(:coffee_pricing_rule) do
    # Buy 3 and unit price drops to 2/3 of original price
    PricingRule.new('CF1', ->(qty, price) { qty >= 3 ? qty * (price * 2 / 3) : qty * price })
  end

  let(:pricing_rules) { [green_tea_pricing_rule, strawberry_pricing_rule, coffee_pricing_rule] }

  subject { described_class.new(pricing_rules) }

  context 'when Basket: GR1,SR1,GR1,GR1,CF1' do
    before do
      subject.scan(green_tea)
      subject.scan(strawberry)
      subject.scan(green_tea)
      subject.scan(green_tea)
      subject.scan(coffee)
    end

    it 'returns total price of 22.45' do
      expect(subject.total).to eq(BigDecimal('22.45'))
    end
  end

  context 'when Basket: GR1,GR1' do
    before do
      subject.scan(green_tea)
      subject.scan(green_tea)
    end

    it 'returns total price of 3.11' do
      expect(subject.total).to eq(BigDecimal('3.11'))
    end
  end

  context 'Basket: SR1,SR1,GR1,SR1' do
    before do
      subject.scan(strawberry)
      subject.scan(strawberry)
      subject.scan(green_tea)
      subject.scan(strawberry)
    end

    it 'returns total price of 16.61' do
      expect(subject.total).to eq(BigDecimal('16.61'))
    end
  end

  context 'Basket: GR1,CF1,SR1,CF1,CF1' do
    before do
      subject.scan(green_tea)
      subject.scan(coffee)
      subject.scan(strawberry)
      subject.scan(coffee)
      subject.scan(coffee)
    end

    it 'returns total price of 30.57' do
      expect(subject.total).to eq(BigDecimal('30.57'))
    end
  end

  context 'when Basket is empty' do
    it 'returns total price of 0' do
      expect(subject.total).to be_zero
    end
  end

  context 'when Basket: GR1,GR1 but there are no pricing rules' do
    subject { described_class.new([]) }

    before do
      subject.scan(green_tea)
      subject.scan(green_tea)
    end

    it 'returns total price of 6.22' do
      expect(subject.total).to eq(BigDecimal('6.22'))
    end
  end

  describe 'scan' do
    context 'when the given product is not an instance of Product' do
      it 'raises an ArgumentError' do
        expect { subject.scan('invalid') }.to raise_error(ArgumentError, 'Invalid product')
      end

      it 'adds the product to the basket' do
        expect { subject.scan(green_tea) }.to change { subject.instance_variable_get(:@basket).size }.by(1)
      end
    end
  end

  describe 'total' do
    context 'when the basket is empty' do
      it 'returns 0' do
        expect(subject.total).to be_zero
      end
    end

    context 'when the basket is not empty' do
      before do
        subject.scan(green_tea)
        subject.scan(strawberry)
      end

      it 'returns the total price of all products in the basket' do
        expect(subject.total).to eq(BigDecimal('8.11'))
      end
    end
  end

  describe 'basket_summary' do
    context 'when the basket is empty' do
      it 'returns an empty array' do
        expect(subject.send(:basket_summary)).to eq([])
      end
    end

    context 'when the basket is not empty' do
      before do
        subject.scan(green_tea)
        subject.scan(strawberry)
        subject.scan(green_tea)
      end

      it 'returns an array of hashes with product code, total quantity present in the basket, and unit price' do
        expect(subject.send(:basket_summary)).to eq(
          [
            { product_code: 'GR1', quantity: 2, price: BigDecimal('3.11') },
            { product_code: 'SR1', quantity: 1, price: BigDecimal('5.00') }
          ]
        )
      end
    end
  end

  describe 'pricing_rule_for_product' do
    context 'when the pricing rule for the given product code is found' do
      it 'returns the pricing rule object' do
        expect(subject.send(:pricing_rule_for_product, 'GR1')).to eq(green_tea_pricing_rule)
      end
    end

    context 'when the pricing rule for the given product code is not found' do
      it 'returns nil' do
        expect(subject.send(:pricing_rule_for_product, 'invalid')).to be_nil
      end
    end
  end

  describe 'calculate_subtotal' do
    context 'with pricing rule' do
      it 'calculates the subtotal based on the pricing rule' do
        expect(subject.send(:calculate_subtotal, 'SR1', 3, BigDecimal('5.00'))).to eq(BigDecimal('13.50'))
      end
    end

    context 'with no pricing rule' do
      subject { described_class.new([]) }
      it 'calculates the subtotal based on the unit price' do
        expect(subject.send(:calculate_subtotal, 'SR1', 2, BigDecimal('5.00'))).to eq(BigDecimal('10.00'))
      end
    end
  end
end
