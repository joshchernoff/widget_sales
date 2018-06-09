RSpec.describe WidgetSales::SOP do
  let(:sop){WidgetSales::SOP.new()}

  it "registers a transactor for later placing orders" do
    
    expect(sop.transactors).to be_empty
    sop.register_transactor(name: "foo", type: :direct, sale_price: 1)
    expect(sop.transactors.count).to eq(1)
    expect(sop.transactors[0]).to be_an_instance_of(WidgetSales::Transactor)
  end

  it "creates a transaction for a given transactor" do
    sop.register_transactor(name: "foo", type: :direct, sale_price: 1)
    expect(sop.transactors[0].total_orders).to eq(0)
    sop.create_transaction(transactor_name: "foo", quantity: 1)
    expect(sop.transactors[0].total_orders).to eq(1)
  end

  it "generates a billing report" do
    sop.register_transactor(name: "Direct", type: :direct, sale_price: 100)
    sop.register_transactor(name: "ACompany", type: :affiliate, sale_price: 75)
    sop.register_transactor(name: "AnotherCompany", type: :affiliate, sale_price: 65)
    sop.register_transactor(name: "EvenMoreCompany", type: :affiliate, sale_price: 80)
    sop.register_transactor(name: "ResellThis", type: :reseller, sale_price: 75)
    sop.register_transactor(name: "SellMoreThings", type: :reseller, sale_price: 85)

    100.times.map{ Random.rand(1..100) }.each do |q|
      transactor = sop.transactors.sample
      sop.create_transaction(transactor_name: transactor.name, quantity: q )
    end

    report = {
      billing: {
        affiliate_billing: {
          "ACompany" => sop.transactors.select{|t| t.name == "ACompany"}.first.total_billing,
          "AnotherCompany" => sop.transactors.select{|t| t.name == "AnotherCompany"}.first.total_billing,
          "EvenMoreCompany" => sop.transactors.select{|t| t.name == "EvenMoreCompany"}.first.total_billing,
        },
        reseller_billing: {
          "ResellThis" => sop.transactors.select{|t| t.name == "ResellThis"}.first.total_billing,
          "SellMoreThings" => sop.transactors.select{|t| t.name == "SellMoreThings"}.first.total_billing,
        },
      }, 
      profits: { 
        affiliate_profits: {
          "ACompany" => sop.transactors.select{|t| t.name == "ACompany"}.first.total_profit, 
          "AnotherCompany" => sop.transactors.select{|t| t.name == "AnotherCompany"}.first.total_profit, 
          "EvenMoreCompany" => sop.transactors.select{|t| t.name == "EvenMoreCompany"}.first.total_profit}, 
        reseller_profits: {
          "ResellThis"=>sop.transactors.select{|t| t.name == "ResellThis"}.first.total_profit, 
          "SellMoreThings"=>sop.transactors.select{|t| t.name == "SellMoreThings"}.first.total_profit
        }
      },
      total_revenue:  sop.transactors.map{|t| t.total_sales}.sum
    }
    expect(sop.billing_report).to eq(report)

  end
end

RSpec.describe WidgetSales::Transactor do
  let(:data){ {name: "foo", type: :direct, sale_price: 1} }
  let(:transactor){ WidgetSales::Transactor.new(data) }

  it "initializes with valid data" do
    data = {name: "foo", type: "bar", sale_price: 1}
    expect( WidgetSales::Transactor.new(data)).to be_an_instance_of(WidgetSales::Transactor)
  end

  it "should persist a name" do
    expect(transactor.name).to eq(data[:name])
  end

  it "should persist a type" do
    expect(transactor.type).to eq(data[:type])
  end

  it "should persist a sales_price" do
    expect(transactor.sale_price).to eq(data[:sale_price])
  end

  it "should create and persist an order" do
    expect(transactor.orders).to be_empty
    transactor.create_order(1)
    expect(transactor.orders.count).to eq(1)
  end

  it "returns a total count for orders it has" do
    expect(transactor.total_orders).to eq(0)
    3.times {|i| transactor.create_order(i) }
    expect(transactor.total_orders).to eq(3)
  end

  it "returns a total sales for all its orders" do
    3.times {|i| transactor.create_order(1) }
    expect(transactor.total_sales).to eq( (data[:sale_price] * 3)) 
  end

  it "returns a total quanitiy for all the orders" do
    3.times {|i| transactor.create_order(1) }
    expect(transactor.total_quantity).to eq( 3 ) 
  end

  it "calculates total profit for a reseller" do
    transactor = WidgetSales::Transactor.new(name: "foo", type: :reseller, sale_price: 50)
    3.times {|i| transactor.create_order(1) }
    expect(transactor.total_profit).to eq( 0 ) 
  end

  it "calculates total profit for a affiliate based on 0 to 500 widgets" do
    transactor = WidgetSales::Transactor.new(name: "foo", type: :affiliate, sale_price: 60)
    
    transactor.create_order(1)
    expect(transactor.total_profit).to eq( 0 )

    transactor.create_order(499)
    expect(transactor.total_profit).to eq( 0 )
  end

  it "calculates total profit for an affiliate based on sales of 501 to 1000" do
    transactor = WidgetSales::Transactor.new(name: "foo", type: :affiliate, sale_price: 50)
    
    transactor.create_order(501)
    expect(transactor.total_profit).to eq( 0 )

    transactor.create_order(499)
    expect(transactor.total_profit).to eq( 0 )
  end

  it "calculates total profit for an affiliate based on sales of 1000 and up" do
    transactor = WidgetSales::Transactor.new(name: "foo", type: :affiliate, sale_price: 40)
    
    transactor.create_order(1001)
    expect(transactor.total_profit).to eq( 0 )

    transactor.create_order(2000000)
    expect(transactor.total_profit).to eq( 0 )
  end

  it "calculates total amount to bill a given reseller for any quantity at a rate of 50" do
    transactor = WidgetSales::Transactor.new(name: "foo", type: :reseller, sale_price: 100)
    
    transactor.create_order(1)
    expect(transactor.total_billing).to eq( 50 )

    transactor.create_order(434343434)
    expect(transactor.total_billing).to eq( (1 + 434343434) * 50 )
  end

  it "calculates total amount to bill a given affiliate for sales between 1 to 500 at a rate of 60" do
    transactor = WidgetSales::Transactor.new(name: "foo", type: :affiliate, sale_price: 100)
    
    transactor.create_order(1)
    expect(transactor.total_billing).to eq( 60 )

    transactor.create_order(499)
    expect(transactor.total_billing).to eq( 500 * 60 )
  end

  it "calculates total amount to bill a given affiliate for sales between 501 to 1000 at a rate of 50" do
    transactor = WidgetSales::Transactor.new(name: "foo", type: :affiliate, sale_price: 100)
    
    transactor.create_order(501)
    expect(transactor.total_billing).to eq( 501 * 50 )

    transactor.create_order(499)
    expect(transactor.total_billing).to eq( 1000 * 50 )
  end

  it "calculates total amount to bill a given affiliate for sales of 1001 and up at a rate of 40" do
    transactor = WidgetSales::Transactor.new(name: "foo", type: :affiliate, sale_price: 100)
    
    transactor.create_order(1001)
    expect(transactor.total_billing).to eq( 1001 * 40 )

    transactor.create_order(3343326)
    expect(transactor.total_billing).to eq( (1001 + 3343326) * 40 )
  end
end

RSpec.describe  WidgetSales::Order do

  let(:data){ {sales_price: 1, quantity: 1} }
  let(:order){ WidgetSales::Order.new(data) }

  it "initializes with valid data" do
    expect(WidgetSales::Order.new(data)).to be_an_instance_of(WidgetSales::Order)
  end

  it "should persist a sales_price" do
    expect(order.sales_price).to eq(data[:sales_price])
  end

  it "should persist a quantity" do
    expect(order.quantity).to eq(data[:quantity])
  end
end
