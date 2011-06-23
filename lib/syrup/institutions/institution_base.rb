module Syrup
  module Institutions
    class InstitutionBase
      
      class << self
        def inherited(subclass)
          @subclasses ||= []
          @subclasses << subclass
        end
        
        def subclasses
          @subclasses
        end
      end
      
      attr_accessor :username, :password, :secret_questions
      
      def initialize
        @accounts = []
      end
      
      def setup
        yield self
        self
      end
      
      def populated?
        @populated
      end
      
      def populated=(value)
        @populated = value
      end
      
      def accounts
        populate_accounts
        @accounts
      end
      
      def find_account_by_id(account_id)
        account = @accounts.find { |a| a.id == account_id }
        unless account || populated?
          account = Account.new(:id => account_id)
          @accounts << account
        end
        account
      end
      
      def populate_account(account_id)
        unless populated?
          result = fetch_account(account_id)
          return nil if result.nil?
          
          if result.respond_to?(:each)
            populate_accounts(result)
            find_account_by_id(account_id)
          else
            result.populated = true
            account = find_account_by_id(account_id)
            account.merge! result if account
          end
        end
      end
      
      def populate_accounts(populated_accounts = nil)
        unless populated?
          all_accounts = populated_accounts || fetch_accounts
          
          # Remove any accounts that were added, that don't actually exist
          # TODO: maybe use reject so that you can mark all the invalid accounts
          @accounts.keep_if { |a| all_accounts.include?(a) }
          
          # Add any additional account information
          new_accounts = []
          all_accounts.each do |filled_account|
            account = @accounts.find { |a| a.id == filled_account.id }
            
            filled_account.populated = true
            
            # If we already had an account with this id, fill it with data
            if account
              account.merge! filled_account
            else
              new_accounts << filled_account
            end
          end
          @accounts |= new_accounts # Uses set union
          
          self.populated = true
        end
      end
      
      def populate_transactions
      end
      
      protected
      
      def agent
        @agent ||= Mechanize.new
      end
        
      def parse_currency(currency)
        currency.scan(/[0-9.]/).join.to_f
      end
      
    end
  end
end