require "spec_helper"

include Institutions

describe InstitutionBase do
  
  before(:each) do
    @institution = InstitutionBase.new
    @institution.stub(:fetch_accounts) do
      [Account.new(:id => 1, :name => 'first')]
    end
  end
  
  it "keeps a list of classes that extend it" do
    expect(InstitutionBase.subclasses).to include(ZionsBank)
    expect(InstitutionBase.subclasses).to include(Uccu)
  end
  
  it "can be setup" do
    institution = InstitutionBase.new
    institution.setup do |config|
      config.username = 'username'
      config.password = 'pass'
      config.secret_questions = { 'Do you like candy?' => 'yes' }
    end
    
    expect(institution.username).to eq('username')
    expect(institution.password).to eq('pass')
    expect(institution.secret_questions['Do you like candy?']).to eq('yes')
  end
  
  context "when accounts are NOT populated" do
    it "fetches them when accessed" do
      @institution.should_receive :fetch_accounts
      @institution.accounts
    end
    
    it "returns an account with the id populated" do
      account = @institution.find_account_by_id 21
      expect(account.id).to eq(21)
    end
    
    it "returns a previously created account if one exists" do
      original_account = @institution.find_account_by_id 3
      different_account = Account.new(:id => 3)
      
      new_account = @institution.find_account_by_id 3
      expect(new_account).to be(original_account)
      expect(new_account).not_to be(different_account)
    end
  end
  
  context "when accounts are populated" do
    before(:each) do
      @institution.populated = true
    end
    
    it "doesn't fetch them again" do
      @institution.should_not_receive :fetch_accounts
      @institution.accounts
    end
    
    it "returns nil if asked for a non-existent account" do
      account = @institution.find_account_by_id 21
      expect(account).to be_nil
    end
  end
  
  
  context "while populating accounts" do
    it "filters out non-existent accounts" do
      @institution.find_account_by_id 21
      @institution.accounts.each do |a|
        expect(a.id).not_to be(21)
      end
    end

    it "populates data in existent accounts" do
      account = @institution.find_account_by_id 1
      @institution.populate_accounts
      expect(account.name).to eq('first')
    end
    
    it "marks accounts as populated" do
      @institution.accounts.each do |account|
        expect(account.populated?).to be(true)
      end
    end
    
    it "marks invalid accounts as invalid" do
      account = @institution.find_account_by_id 21
      @institution.populate_accounts
      expect(account.valid?).to be(false)
    end
  end
  
  context "when asked to populate one account" do
    it "populates one account" do
      @institution.stub(:fetch_account) do
        Account.new :id => 2, :name => 'single account'
      end
      
      account = @institution.populate_account(2)
      expect(account.name).to eq('single account')
      expect(account.populated?).to be(true)
    end
    
    it "can populate all accounts" do
      @institution.stub(:fetch_account) do
        [Account.new(:id => 2, :name => 'single account')]
      end
      
      invalid_account = @institution.find_account_by_id 21
      @institution.populate_account(2)
      expect(@institution.populated?).to be(true)
    end
  end
  
  # it "populates transactions"
  
end
