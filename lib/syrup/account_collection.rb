module Syrup
  class AccountCollection
    
    include Enumerable
    
    def initialize(institution)
      @institution = institution
    end
    
    def each(&blk)

      unless @fetched_all_accounts
        all_accounts = @institution.fetch_accounts
        all_accounts.each do |filled_account|
          account = accounts.find { |a|
            puts 'a is nil' if a.nil?
            puts 'filled_a is nil' if filled_account.nil?
              
            a.id == filled_account.id }
          # If we already had an account with this id, fill it with data
          if account
            filled_account.instance_variables.each do |filled_var|
              account.instance_variable_set(filled_var, filled_account.instance_variable_get(filled_var))
            end
          else
            accounts << account
          end
        end
        
        # Remove any accounts that were added, that don't actually exist
        accounts.keep_if { |a| all_accounts.find { |a2| a.id == a2.id } }
        
        @fetched_all_accounts = true
      end
      
      @account.each(&blk)
    end
    
    def find_by_id(id)
      account = accounts.find { |a| a.id == id }
      account ||= Account.new(:id => id)

      accounts << account
      
      account
    end
    
    private
    
    def accounts
      @accounts ||= []
    end
    
  end
end