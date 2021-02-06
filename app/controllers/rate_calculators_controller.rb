class RateCalculatorsController < ApplicationController
  include FinanceCalculation

  def index
    # @principal_balance = params["unpaid_principal_balance"].to_f
    # @wac = params["wac"].to_f
    # @servicing_fee = params["servicing_fee"].to_f
    # @remaining_amortization_term = params["remaining_amortization_term"].to_f
    # @remaining_term_to_maturity = params["remaining_term_to_maturity"].to_i
    # @loss_assumption = params["loss_assumption"].to_f
    # @prepayment_assumption = params["prepayment_assumption"].to_f
    # @price_paid = params["price_paid"].to_f

    # unless params["principal_balance"] && params["duration"] && params["wac"] 
    #   flash[:errors] = "Please enter all required fields.."
    #   redirect_to rate_calculators_new_path and return true
    # else
      @principal_balance = params["unpaid_principal_balance"].to_f #params["principal_balance"].to_f
      @wac = params["wac"].to_f
      @duration = params["remaining_amortization_term"].to_f #params["duration"].to_i 
      @servicing_fee = params["servicing_fee"].to_f
      @scheduled_interest = calculate_scheduled_interest(@principal_balance, @wac).round
      @scheduled_payment = calculate_scheduled_payment
      @scheduled_principal = calculate_scheduled_principal
      @ending_perf_balance = ending_performing_balance
      set_arrays_of_calculations
    # end
  end

  def new; end

  private

  def calculate_scheduled_interest(principal_balance, wac)
    (principal_balance * wac)/(12 * 100)
  end

  def calculate_scheduled_payment
    FinanceCalculation::Loan.new(nominal_rate: @wac, duration: @duration, amount: @principal_balance, structure_fee: @servicing_fee).pmt
  end

  def calculate_scheduled_principal
    (calculate_scheduled_payment - calculate_scheduled_interest(@principal_balance, @wac)).round rescue 0
  end

  def ending_performing_balance
    @principal_balance - @scheduled_principal
  end

  def calculate_servicing_fee(perf_principal)
    (perf_principal*@servicing_fee)/(12*100) 
  end

  def calculate_received_interest(scheduled_interest, servicing_fee)
    scheduled_interest - servicing_fee
  end

  def set_arrays_of_calculations
    @payments = []
    @interests = []
    @principals = []
    @end_perf_balances = []
    @servicing_fees = []
    @received_interests = []
    
    for i in(0..@duration)
      if i==0
        @payments << @principal_balance # begining principle
        @interests << calculate_scheduled_interest(@principal_balance, @wac) # scheduled interest
        @principals << @scheduled_principal # Scheduled Principal
        @servicing_fees << calculate_servicing_fee(@principal_balance) #servicing_fees
        @end_perf_balances << @ending_perf_balance # Ending perf balance
        @received_interests << calculate_received_interest(@interests[i], @servicing_fees[i]) #received_interest
      else
        @payments << @end_perf_balances[i-1]
        @interests << calculate_scheduled_interest(@payments[i], @wac)
        @principals << (@scheduled_payment - @interests[i])
        @servicing_fees << calculate_servicing_fee(@payments[i])
        @end_perf_balances << (@payments[i] - @principals[i])
        @received_interests << calculate_received_interest(@interests[i], @servicing_fees[i])
      end 
    end
  end
end
