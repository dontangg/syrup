module Syrup
  class Transaction
    attr_accessor :payee, :amount, :posted_at
    
    def initialize(attr_hash)
      attr_hash.each do |k, v|
        instance_variable_set "@#{k}", v
      end
    end
  end
end