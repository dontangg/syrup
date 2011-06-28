module Syrup
  class Transaction
    ##
    # :attr_accessor: status
    # Currently, the only valid types are :posted and :pending
    
    #
    attr_accessor :id, :payee, :amount, :posted_at, :status
    
    # New objects can be instantiated as either empty (pass no construction parameter) or pre-set with
    # attributes (pass a hash with key names matching the associated attribute names).
    def initialize(attr_hash = nil)
      if attr_hash
        attr_hash.each do |k, v|
          instance_variable_set "@#{k}", v
        end
      end
    end
  end
end