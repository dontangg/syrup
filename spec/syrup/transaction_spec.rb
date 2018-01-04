require "spec_helper"

describe Syrup::Transaction do

  before(:all) do
    @transaction = Transaction.new :amount => 10, :payee => "Newegg", :posted_at => DateTime.now
  end
  
  it "has an amount" do
    expect(@transaction.amount).not_to be_nil
  end
  
  it "has a payee" do
    expect(@transaction.payee).not_to be_nil
  end
  
  it "has a posted-at date" do
    expect(@transaction.posted_at).not_to be_nil
  end
  
end