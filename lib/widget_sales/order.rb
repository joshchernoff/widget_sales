module WidgetSales
  class Order
    attr_reader :sales_price, :quantity
    def initialize(sales_price:, quantity:)
      @sales_price = sales_price
      @quantity = quantity
    end
  end
end
