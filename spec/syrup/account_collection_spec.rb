require "spec_helper"

describe AccountCollection do
  
  before(:each) do
    @institution = double()
    @institution.stub(:fetch_accounts) do
      accounts = []
      accounts << Account.new(:id => 1, :name => 'first')
      accounts << Account.new(:id => 2, :name => 'next')

      accounts
    end
    
    @account_collection = AccountCollection.new(@institution)
  end
  
  it "is enumerable" do
    @account_collection.should respond_to(:each)
    @account_collection.should respond_to(:find)
    @account_collection.should respond_to(:any?)
  end
  
  context "while populating" do
    
    it "filters out non-existent accounts" do
      @account_collection.find_by_id 21
      @account_collection.each do |a|
        a.id.should_not be(21)
      end
    end
    
    it "populates data in existent accounts" do
      account = @account_collection.find_by_id 1
      @account_collection.each
      account.name.should == 'first'
    end
    
  end
  
  context "given an id before accounts have been fetched" do
    it "returns an account with the id populated" do
      account = @account_collection.find_by_id 3
      
      account.id.should be(3)
    end
    
    it "returns a previously created account if one exists" do
      original_account = @account_collection.find_by_id 3
      different_account = Account.new(:id => 3)
      
      new_account = @account_collection.find_by_id 3
      new_account.should be(original_account)
      new_account.should_not be(different_account)
    end
  end
  
  context "when accounts are already populated" do
    before(:each) do
      @account_collection.each
    end
    
    it "doesn't fetch them again" do
      @institution.should_not_receive :fetch_accounts
      @account_collection.find_by_id 1
    end
    
    it "returns nil if asked for a non-existent account" do
      account = @account_collection.find_by_id 21
      account.should be_nil
    end
  end
end