require "./lib/widget_sales/order"
module WidgetSales
  class Transactor

    attr_reader :name, :type, :sale_price, :orders
    def initialize(name:, type:, sale_price:)
      @name = name
      @type = type
      @sale_price = sale_price
      @orders = []
    end

    def create_order(quantity)
      @orders.push Order.new(sales_price: @sale_price, quantity: quantity)
    end

    def total_orders
      @orders.count
    end

    def total_sales
      @sale_price * total_quantity
    end

    def total_quantity
      @orders.map(&:quantity).sum
    end

    def total_billing
      case @type
      when :affiliate then affiliate_billing_price() * total_quantity
      when :reseller then reseller_billing_price() * total_quantity
      end
    end

    def total_profit
      total_sales - total_billing
    end

    private def reseller_billing_price
      50
    end

    private def affiliate_billing_price
      case total_quantity
        when 0..500 then 60
        when 501..1000 then 50
        when 1001..Float::INFINITY then 40
      end
    end

  end
end
