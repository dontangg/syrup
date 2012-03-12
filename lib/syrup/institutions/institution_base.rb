module Syrup
  module Institutions
    class InstitutionBase
      
      class << self
        # This method is called whenever a class inherits from this class. We keep track of
        # all of them because they should all be institutions. This way we can provide a
        # list of supported institutions via code.
        def inherited(subclass)
          @subclasses ||= []
          @subclasses << subclass
        end
        
        # Returns an array of all classes that inherit from this class. Or, in other words,
        # an array of all supported institutions
        def subclasses
          @subclasses
        end
      end
      
      ##
      # :attr_writer: populated
      
      ##
      # :attr_reader: populated?
      
      ##
      # :attr_reader: agent
      # Gets an instance of Mechanize for use by any subclasses.
      
      ##
      # :attr_reader: accounts
      # Returns an array of all of the user's accounts at this institution.
      # If accounts hasn't been populated, it populates accounts and then returns them.
      
      #
      attr_accessor :username, :password, :secret_questions
      
      def initialize
        @accounts = []
      end
      
      # This method allows you to setup an institution with block syntax
      #
      #   InstitutionBase.setup do |config|
      #     config.username = 'my_user"
      #     ...
      #   end
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
      
      # Returns an account with the specified +account_id+. Always use this method to
      # create a new `Account` object. If you do, it will get populated correctly whenever
      # the population occurs.
      def find_account_by_id(account_id)
        account = @accounts.find { |a| a.id == account_id }
        unless account || populated?
          account = Account.new(:id => account_id, :institution => self)
          @accounts << account
        end
        account
      end
      
      # Populates an account given an `account_id`. The implementing institution may populate
      # all accounts when this is called if there isn't a way to only request one account's
      # information.
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
      
      # Populates all of the user's accounts at this institution.
      def populate_accounts(populated_accounts = nil)
        unless populated?
          all_accounts = populated_accounts || fetch_accounts
          
          # Remove any accounts that were added, that don't actually exist
          @accounts.delete_if do |a|
            if all_accounts.include?(a)
              false
            else
              a.valid = false
              true
            end
          end
          
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
      
      protected
      
      def agent
        unless @agent
          @agent = Mechanize.new

          # Provide path to cert bundle for Windows
          # Downloaded from http://curl.haxx.se/ca/
          @agent.agent.http.ca_file = File.expand_path(File.dirname(__FILE__) + "/cacert.pem") if RUBY_PLATFORM =~ /mingw|mswin/i
        end

        @agent
      end
      
      # This is just a helper method that simplifies the common process of extracting a number
      # from a string representing a currency.
      # 
      #   parse_currency('$ 1,234.56') #=> 1234.56
      def parse_currency(currency)
        currency.scan(/[0-9.]/).join.to_f
      end
      
      # A helper method that replaces a few HTML entities with their actual characters
      #
      #   unescape_html("You &amp; I") #=> "You & I"
      def unescape_html(str)
        str.gsub(/&(.*?);/n) do
          match = $1.dup
          case match
          when /\Aamp\z/ni           then '&'
          when /\Aquot\z/ni          then '"'
          when /\Agt\z/ni            then '>'
          when /\Alt\z/ni            then '<'
          when /\A#0*(\d+)\z/n       then
            if Integer($1) < 256
              Integer($1).chr
            else
              if Integer($1) < 65536 and ($KCODE[0] == ?u or $KCODE[0] == ?U)
                [Integer($1)].pack("U")
              else
                "&##{$1};"
              end
            end
          when /\A#x([0-9a-f]+)\z/ni then
            if $1.hex < 256
              $1.hex.chr
            else
              if $1.hex < 65536 and ($KCODE[0] == ?u or $KCODE[0] == ?U)
                [$1.hex].pack("U")
              else
                "&#x#{$1};"
              end
            end
          else
            "&#{match};"
          end
        end
      end
      
    end
  end
end
