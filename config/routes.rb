Rails.application.routes.draw do

  root :to => 'rate_calculators#new'

  get 'rate_calculators/new'
  get 'rate_calculators/index'
end
