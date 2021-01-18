class RateCalculatorsController < ApplicationController
  include FinanceCalculation

  def index
    @princinpal_balance = params["principal_balance"].to_f
    @wac = params["wac"].to_f
    @duration = params["duration"].to_i
    @servicing_fee = params["servicing_fee"].to_f
    @scheduled_interest = calculate_scheduled_interest.round
    @scheduled_payment = calculate_scheduled_payment.round
    @scheduled_principal = calculate_scheduled_principal
    @ending_perf_balance = ending_performing_balance
  end

  def new; end

  private

  def calculate_scheduled_interest
    ((@princinpal_balance * @wac)/(12 * 100)) 
  end

  def calculate_scheduled_payment
    FinanceCalculation::Loan.new(nominal_rate: @wac, duration: @duration, amount: @princinpal_balance, structure_fee: @servicing_fee).pmt
  end

  def calculate_scheduled_principal
    (calculate_scheduled_payment - calculate_scheduled_interest).round
  end

  def ending_performing_balance
    @princinpal_balance - @scheduled_principal
  end

end
