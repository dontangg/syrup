require "spec_helper"

include Institutions

describe BankAf, :bank_integration => true do
  before(:each) do
    @bank = BankAf.new
    @bank.setup do |config|
      config.username = ""
      config.password = ""
      config.secret_questions = {}
    end
  end
  
  it "fetches one account"
  it "fetches all accounts" do
    accounts = @bank.fetch_accounts
    accounts.each do |account|
      puts "#{account.id} #{account.name}"
    end
  end
  
  it "fetches transactions given a date range" do
    account_id = 'Checking'
  
    account = @bank.find_account_by_id(account_id)
    account.instance_variable_get(:@prior_day_balance).should be_nil
    account.instance_variable_get(:@current_balance).should be_nil
    account.instance_variable_get(:@available_balance).should be_nil
    
    @bank.fetch_transactions(account_id, Date.today - 30, Date.today)
    
    puts account.prior_day_balance
    puts account.current_balance
    puts account.available_balance
    
    #account.prior_day_balance.should_not be_nil
    account.current_balance.should_not be_nil
    account.available_balance.should_not be_nil
  end
end
