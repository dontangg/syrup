require "spec_helper"

describe Syrup do
  it "lists all institutions" do
    institution_list = Syrup.institutions
    
    institution_list.size.should == 1
    
    institution_list.should include(Institutions::ZionsBank)
    
    institution_list.each do |institution|
      institution.should respond_to(:name)
      institution.should respond_to(:id)
    end
  end
  
  it "returns nil if you try to setup an unknown institution" do
    Syrup.setup_institution('unknown', 'user', 'pass', {}).should be_nil
  end
  
  it "sets up a Zions Bank institution" do
    username = "user"
    password = "pass"
    secret_questions = { 'Do you eat?' => 'yes' }
    
    zions = Syrup.setup_institution('zions_bank', username, password, secret_questions)
    
    zions.should_not be_nil
    zions.class.should == Syrup::Institutions::ZionsBank
    zions.username.should == username
  end
end