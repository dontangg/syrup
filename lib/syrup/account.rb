require 'date'

module Syrup
  # An account contains all the information related to the account. Information
  # is loaded lazily so that you can use an account to get transactions without
  # incurring the cost of getting any account information.
  class Account
    ##
    # :attr_reader: name
    # Gets the name of the account (eg. "Don's Checking").
    
    ##
    # :attr_reader: type
    # Gets the type of account. Currently, the only valid types are :deposit and :credit.
    
    ##
    # :attr_reader: account_number
    
    ##
    # :attr_reader: available_balance
    
    ##
    # :attr_reader: current_balance
    
    ##
    # :attr_reader: prior_day_balance
    
    ##
    # :attr_reader: populated?
    
    ##
    # :attr_writer: populated
    
    ##
    # :attr_reader: valid?
    # Since account information is lazily loaded, the validity of this account isn't immediately
    # known. Once this account has been populated, this will return true if the account is a
    # valid account, nil otherwise. Calling this method causes the account to attempt to be populated.
    
    ##
    # :attr_writer: valid
    
    #
    attr_accessor :id
    attr_writer :name, :type, :account_number, :current_balance, :available_balance, :prior_day_balance
    
    
    def name
      populate
      @name
    end
    
    def type
      populate
      @type
    end
    
    def account_number
      populate
      @account_number
    end
    
    def current_balance
      populate
      @current_balance
    end
    
    def available_balance
      populate
      @available_balance
    end
    
    def prior_day_balance
      populate
      @prior_day_balance
    end
    
    # New objects can be instantiated as either empty (pass no construction parameter) or pre-set with
    # attributes (pass a hash with key names matching the associated attribute names).
    def initialize(attr_hash = nil)
      if attr_hash
        attr_hash.each do |k, v|
          instance_variable_set "@#{k}", v
        end
      end
      
      @cached_transactions = []
    end
    
    def populated?
      @populated
    end
    
    def populated=(value)
      @populated = value
    end
    
    # Populates this account with all of its information
    def populate
      unless populated? || @institution.nil?
        raise "The account id must not be nil when populating an account" if id.nil?
        @institution.populate_account(id)
      end
    end
    
    # Tests equality of this account with another account. Accounts are considered equal
    # if they have the same id.
    def ==(other_account)
      other_account.id == self.id && other_account.is_a?(Account)
    end
    
    # Returns an array of transactions from this account for the supplied date range.
    def find_transactions(starting_at, ending_at = Date.today)
      return [] if starting_at > ending_at
      
      @institution.fetch_transactions(self.id, starting_at, ending_at)
    end
    
    # Merges this account information with another account. The other account's information
    # overrides this account's.
    def merge!(account_with_info)
      if account_with_info
        account_with_info.instance_variables.each do |filled_var|
          self.instance_variable_set(filled_var, account_with_info.instance_variable_get(filled_var))
        end
      end
      self
    end
    
    def valid?
      if @valid.nil?
        populate
        @valid = populated?
      end
      @valid
    end
    
    def valid=(validity)
      @valid = validity
    end
    
  end
end