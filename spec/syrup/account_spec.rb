require "spec_helper"

describe Account do
  before(:each) do
    @institution = double()
    @institution.stub(:fetch_accounts) do
      accounts = []
      accounts << Account.new(:id => 1, :name => 'first')
      accounts << Account.new(:id => 2, :name => 'next')

      accounts
    end
  end
  
  it "has lots of useful properties" do
    account = Account.new

    account.should respond_to(:id)
    account.should respond_to(:name)
    account.should respond_to(:type)
    account.should respond_to(:account_number)
    account.should respond_to(:current_balance)
    account.should respond_to(:available_balance)
    account.should respond_to(:prior_day_balance)
  end
  
  it "can fetch its account information when properties are accessed"
  
  it "doesn't allow there to be too many cached transactions"
  
  it "is considered == if the id is the same" do
    account1 = Account.new :id => 1, :name => "checking"
    account2 = Account.new :id => 1, :name => "savings"
    account3 = Account.new :id => 2, :name => "trash"
    
    account1.should == account2
    account1.should_not == account3
  end
  
  context "given a date range" do
    it "gets transactions"
    it "only fetches transactions when needed"
  end
end