# frozen_string_literal: true

require 'checkout'
require 'product'
require 'pricing_rule'

RSpec.describe Checkout do
  let(:green_tea) { Product.new('GR1', 'Green Tea', 3.11) }
  let(:strawberry) { Product.new('SR1', 'Strawberry', 5.00) }
  let(:coffee) { Product.new('CF1', 'Coffee', 11.23) }

  let(:green_tea_pricing_rule) do
    # Buy one get one free
    PricingRule.new('GR1', ->(qty, price) { (qty / 2.0).ceil * price })
  end

  let(:strawberry_pricing_rule) do
    # Bulk discount - buy 3 or more and price drops to 4.50
    PricingRule.new('SR1', ->(qty, _price) { qty >= 3 ? qty * 4.50 : qty * 5.00 })
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
      expect(subject.total).to eq(22.45)
    end
  end

  context 'when Basket: GR1,GR1' do
    before do
      subject.scan(green_tea)
      subject.scan(green_tea)
    end

    it 'returns total price of 3.11' do
      expect(subject.total).to eq(3.11)
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
      expect(subject.total).to eq(16.61)
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
      expect(subject.total).to eq(30.57)
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
      expect(subject.total).to eq(6.22)
    end
  end

  describe 'scan' do
    context 'when the given product is not an instance of Product' do
      it 'raises an ArgumentError' do
        expect { subject.scan('invalid') }.to raise_error(ArgumentError, 'Invalid product')
      end
    end
  end
end
