require "spec_helper"

describe Syrup::Institutions::ZionsBank do
  it "correctly initializes properties" do
    username = "user"
    password = "pass"
    secret_questions = { 'Do you eat?' => 'yes' }
    
    zions = Institutions::ZionsBank.new(username, password, secret_questions)
    
    zions.username.should be(username)
    zions.password.should be(password)
    zions.secret_questions.should be(secret_questions)
  end
  
  it "lists one account"
  it "lists all accounts"
  it "lists transactions given a date range"
end