require "spec_helper"

describe Syrup::Institutions::ZionsBank do
  it "correctly initializes properties" do
    username = "user"
    password = "pass"
    secret_questions = { 'Do you eat?' => 'yes' }
    
    zions = Institutions::ZionsBank.new(username, password, secret_questions)
    
    zions.username.should == username
    zions.password.should == password
    zions.secret_questions.should == secret_questions
  end
  
  it "lists all accounts"
  it "gets transactions without getting a list of accounts"
  it "lists transactions given a date range"
end