require "spec_helper"

describe Account do
  before(:each) do
    @institution = double()
    @institution.stub(:populate_account) do
      @account.populated = true
      @account.instance_variable_set :@name, 'my name'
    end
    @institution.stub(:fetch_transactions) do
      [
        Transaction.new(:id => 1, :payee => 'Wal-Mart', :posted_at => Date.today - 1, :amount => 30.14),
        Transaction.new(:id => 2, :payee => 'Pizza Hut', :posted_at => Date.today - 2, :amount => 10.23)
      ]
    end
    @account = Account.new :id => 1, :institution => @institution
  end
  
  it "has lots of useful properties" do
    account = Account.new

    expect(account).to respond_to(:id)
    expect(account).to respond_to(:name)
    expect(account).to respond_to(:type)
    expect(account).to respond_to(:account_number)
    expect(account).to respond_to(:current_balance)
    expect(account).to respond_to(:available_balance)
    expect(account).to respond_to(:prior_day_balance)
  end
  
  it "is populated when properties are accessed" do
    @account.instance_variable_get(:@name).should be_nil
    expect(@account.name).to eq("my name")
  end
  
  it "is considered == if the id is the same" do
    account1 = Account.new :id => 1, :name => "checking"
    account2 = Account.new :id => 1, :name => "savings"
    account3 = Account.new :id => 2, :name => "trash"
    
    expect(account1).to eq(account2)
    expect(account1).not_to eq(account3)
  end
  
  context "given a date range" do
    it "gets transactions" do
      @account.find_transactions(Date.today - 30)
    end
    #it "only fetches transactions when needed"
  end

  #it "doesn't allow there to be too many cached transactions"
end