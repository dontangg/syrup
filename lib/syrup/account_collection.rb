module Syrup
  class AccountCollection
    
    include Enumerable
    
    def initialize(institution)
      @institution = institution
      @accounts = []
    end
    
    def each(&blk)

      unless @fetched_all_accounts
        all_accounts = @institution.fetch_accounts
        
        # Remove any accounts that were added, that don't actually exist
        @accounts.keep_if { |a| all_accounts.include?(a) }
        
        # Add any additional account information
        new_accounts = []
        all_accounts.each do |filled_account|
          account = @accounts.find { |a| a.id == filled_account.id }
          
          # If we already had an account with this id, fill it with data
          if account
            filled_account.instance_variables.each do |filled_var|
              account.instance_variable_set(filled_var, filled_account.instance_variable_get(filled_var))
            end
          else
            new_accounts << filled_account
          end
        end
        @accounts |= new_accounts
        
        @fetched_all_accounts = true
      end
      
      @accounts.each(&blk)
    end
    
    def find_by_id(id)
      account = @accounts.find { |a| a.id == id }
      
      unless account || @fetched_all_accounts
        account = Account.new(:id => id)
        @accounts << account
      end
      
      account
    end
    
  end
end
