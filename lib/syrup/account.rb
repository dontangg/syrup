module Syrup
  class Account
    # known types are :deposit and :credit
    attr_accessor :id, :name, :type, :account_number, :current_balance, :available_balance, :prior_day_balance
    
  end
end