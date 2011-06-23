require "spec_helper"

describe Syrup do
  it "lists all institutions" do
    institution_list = Syrup.institutions
    
    institution_list.size.should be(1)
    
    institution_list.should include(Institutions::ZionsBank)
    
    institution_list.each do |institution|
      institution.should respond_to(:name)
      institution.should respond_to(:id)
    end
  end
  
  it "returns nil if you try to setup an unknown institution" do
    Syrup.setup_institution('unknown').should be_nil
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
    
    zions.should_not be_nil
    zions.class.should be(Syrup::Institutions::ZionsBank)
    zions.username.should be(username)
  end
end