require "spec_helper"

describe Syrup::Transaction do

  before(:all) do
    @transaction = Transaction.new :amount => 10, :payee => "Newegg", :posted_at => DateTime.now
  end
  
  it "has an amount" do
    @transaction.amount.should_not be_nil
  end
  
  it "has a payee" do
    @transaction.payee.should_not be_nil
  end
  
  it "has a posted-at date" do
    @transaction.posted_at.should_not be_nil
  end
  
end