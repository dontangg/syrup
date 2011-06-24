require "spec_helper"

include Institutions

describe ZionsBank, :bank_integration => true do
  before(:each) do
    @bank = ZionsBank.new
    @bank.setup do |config|
      config.username = ""
      config.password = ""
      config.secret_questions = {}
    end
  end
  
  it "fetches one account"
  it "fetches all accounts" do
    accounts = @bank.fetch_accounts
    accounts.each do |account|
      puts "#{account.id} #{account.name}"
    end
  end
  it "fetches transactions given a date range"
end