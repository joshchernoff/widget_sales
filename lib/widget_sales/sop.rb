# The SOP (Standard Operating Procedures) is the main interface
# for registering transactors, creating orders and running reports.

require "./lib/widget_sales/transactor"
module WidgetSales
  class SOP
    attr_reader :transactors

    def initialize
      @transactors = []
    end

    # A roster of sales reps who can create orders
    def register_transactor(args)
      @transactors.push( Transactor.new(args) )
    end

    # A method for submiting a order for a given sales rep
    def create_transaction(transactor_name:, quantity:)
      transactor = find_transactor(transactor_name)
      transactor.create_order(quantity)
    end

    # A basic report of the current state of sales
    def billing_report()
      {
        billing: {
          affiliate_billing: affiliate_billing(),
          reseller_billing: reseller_billing(),
        },
        profits: {
          affiliate_profits: affiliate_profits(),
          reseller_profits: reseller_profits(),
        },
        total_revenue: total_revenue
      }
    end

    private def find_transactor(name)
      @transactors.select{|t| t.name == name}.first
    end

    private def affiliate_billing
      affiliates = @transactors.select{|transactor| transactor.type == :affiliate}
      affiliates.map{|affiliate| [affiliate.name, affiliate.total_billing]}.to_h
    end

    private def reseller_billing
      resellers = @transactors.select{|transactor| transactor.type == :reseller}
      resellers.map{|reseller| [reseller.name, reseller.total_billing]}.to_h
    end

    private def affiliate_profits
      affiliates = @transactors.select{|transactor| transactor.type == :affiliate}
      affiliates.map{|affiliate| [affiliate.name, affiliate.total_profit]}.to_h
    end

    private def reseller_profits
      resellers = @transactors.select{|transactor| transactor.type == :reseller}
      resellers.map{|reseller| [reseller.name, reseller.total_profit]}.to_h
    end

    private def total_revenue
      @transactors.map{|transactor| transactor.total_sales }.sum
    end

  end
end
