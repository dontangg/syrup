require "spec_helper"

describe Syrup do
  it "lists all institutions" do
    institution_list = Syrup.institutions
    
    expect(institution_list.size).to be(3)
    
    expect(institution_list).to include(Institutions::ZionsBank)
    expect(institution_list).to include(Institutions::Uccu)
    
    institution_list.each do |institution|
      expect(institution).to respond_to(:name)
      expect(institution).to respond_to(:id)
      
      inst = institution.new
      expect(inst).to respond_to(:fetch_account)
      expect(inst).to respond_to(:fetch_accounts)
      expect(inst).to respond_to(:fetch_transactions)
    end
  end
  
  it "returns nil if you try to setup an unknown institution" do
    expect(Syrup.setup_institution('unknown')).to be_nil
  end
  
  it "sets up a Zions Bank institution" do
    username = "user"
    password = "pass"
    secret_questions = { 'Do you eat?' => 'yes' }
    
    zions = Syrup.setup_institution('zions_bank') do |config|
      config.username = username
      config.password = password
      config.secret_questions = secret_questions
    end
    
    expect(zions).not_to be_nil
    expect(zions.class).to be(Syrup::Institutions::ZionsBank)
    expect(zions.username).to be(username)
  end

  it "sets up a Uccu institution" do
    username = "user"
    password = "pass"
    secret_questions = { 'Do you eat?' => 'yes' }
    
    zions = Syrup.setup_institution('uccu') do |config|
      config.username = username
      config.password = password
      config.secret_questions = secret_questions
    end
    
    expect(zions).not_to be_nil
    expect(zions.class).to be(Syrup::Institutions::Uccu)
    expect(zions.username).to be(username)
  end
end
