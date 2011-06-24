module Syrup
  class Transaction
    attr_accessor :id, :payee, :amount, :posted_at
    
    def initialize(attr_hash = nil)
      if attr_hash
        attr_hash.each do |k, v|
          instance_variable_set "@#{k}", v
        end
      end
    end
  end
end