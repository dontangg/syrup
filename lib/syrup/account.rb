module Syrup
  class Account
    # known types are :deposit and :credit
    attr_accessor :id, :name, :type, :account_number, :current_balance, :available_balance, :prior_day_balance
    
    def initialize(attr_hash)
      attr_hash.each do |k, v|
        instance_variable_set "@#{k}", v
      end
    end
    
  end
end