module FinanceCalculation
  class Loan
    attr_accessor :duration
    attr_accessor :amount
    attr_accessor :nominal_rate
    attr_reader :monthly_rate
    attr_reader :currency_protection
    attr_reader :structure_fee
    attr_reader :principal
    attr_reader :fee
    
    def initialize(options = {})
      initialize_options(options)
      @principal = principal_calculation
      @monthly_rate = @nominal_rate / 100 / 12
    end

    def pmt(options = {})
      future_value = options.fetch(:future_value, 0)
      type = options.fetch(:type, 0)
      ((@amount * interest(@monthly_rate, @duration) - future_value ) / ((1.0 + @monthly_rate * type) * fvifa(@monthly_rate, duration)))
    end

    def apr
      @apr ||= calculate_apr
    end

    protected

      def pow1pm1(x, y)
        (x <= -1) ? ((1 + x) ** y) - 1 : Math.exp(y * Math.log(1.0 + x)) - 1
      end

      def pow1p(x, y)
        (x.abs > 0.5) ? ((1 + x) ** y) : Math.exp(y * Math.log(1.0 + x))
      end

      def interest(monthly_rate, duration)
        pow1p(monthly_rate, duration)
      end

      def fvifa(monthly_rate, duration)
        (monthly_rate == 0) ? duration : pow1pm1(monthly_rate, duration) / monthly_rate
      end

    private

      def initialize_options(options)
        @nominal_rate = options.fetch(:nominal_rate).to_f
        @duration = options.fetch(:duration).to_f
        @amount = options.fetch(:amount).to_f
        @structure_fee = options.fetch(:structure_fee, 5).to_f
        @currency_protection = options.fetch(:currency_protection, 3).to_f
        @fee = options.fetch(:fee, 0).to_f
      end

      def principal_calculation
        amount * (1 - currency_protection/100 - structure_fee / 100 ) - fee * duration
      end

      def calculate_apr
        payment_ratio = pmt / principal_calculation
        duration = @duration
        f = lambda {|k| (k**(duration + 1) - (k**duration * (payment_ratio + 1)) + payment_ratio)}
        f_deriv = lambda { |k| ((duration + 1) * k**duration) - (duration * (payment_ratio + 1) * k**(duration - 1))}

        root = newton_raphson(f, f_deriv, monthly_rate + 1)
        100 * 12 * (root -1).to_f
      end

      def newton_raphson(f, f_deriv, start, precision = 5)
        k_plus_one = start
        k = 0.0
        while ((k - 1) * 10**precision).to_f.floor !=  ((k_plus_one - 1) * 10**precision).to_f.floor
          k = k_plus_one
          k_plus_one = k - f.call(k) / f_deriv.call(k).abs
        end
        k_plus_one
      end
  end
end
