class RateCalculatorsController < ApplicationController
  include FinanceCalculation

  def index
    unless params["principal_balance"] && params["duration"] && params["wac"] 
      flash[:errors] = "Please enter all required fields.."
      redirect_to rate_calculators_new_path and return true
    else
      @principal_balance = params["principal_balance"].to_f
      @wac = params["wac"].to_f
      @duration = params["duration"].to_i
      @servicing_fee = params["servicing_fee"].to_f
      @scheduled_interest = calculate_scheduled_interest(@principal_balance, @wac).round
      @scheduled_payment = calculate_scheduled_payment
      @scheduled_principal = calculate_scheduled_principal
      @ending_perf_balance = ending_performing_balance
      set_arrays_of_calculations
    end
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

  def set_arrays_of_calculations
    @payments = []
    @interests = []
    @principals = []
    @end_perf_balances = []
    
    for i in(0..@duration)
      if i==0
        @payments << @principal_balance # begining principle
        @interests << calculate_scheduled_interest(@principal_balance, @wac) # scheduled interest
        @principals << @scheduled_principal # Scheduled Principal
        @end_perf_balances << @ending_perf_balance # Ending perf balance
      else
        @payments << @end_perf_balances[i-1]
        @interests << calculate_scheduled_interest(@payments[i], @wac)
        @principals << (@scheduled_payment - @interests[i])
        @end_perf_balances << (@payments[i] - @principals[i])
      end 
    end
  end
end
