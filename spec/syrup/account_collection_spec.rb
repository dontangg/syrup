require "spec_helper"

describe AccountCollection do
  
  before(:each) do
    @institution = double()
    @account_collection = AccountCollection.new(@institution)
  end
  
  it "is enumerable"
  
  context "while populating" do
    it "filters out non-existent accounts" do
      @institution.stub(:fetch_accounts) do
        accounts = []
        accounts << Account.new(:id => 1, :name => 'first')
        accounts << Account.new(:id => 2, :name => 'next')
        
        accounts
      end
      
      @account_collection.find_by_id 21
      @account_collection.each { |a| a }
      
      pending "Finish this test"
    end
  end
  
  context "given an id" do
    it "returns an account with the id populated" do
      account = @account_collection.find_by_id 3
      
      account.id.should be(3)
    end
    
    it "returns a previously created account if one exists" do
      account = @account_collection.find_by_id 3
      account.name = "test account"
      
      account = @account_collection.find_by_id 3
      account.name.should == "test account"
    end
  end
  
  context "when accounts are already populated" do
    it "doesn't fetch them again"
    it "returns nil if asked for a non-existent account"
  end
end