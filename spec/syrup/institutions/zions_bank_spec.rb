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

  #it "fetches one account"
  it "fetches all accounts" do
    accounts = @bank.fetch_accounts
    accounts.each do |account|
      puts "#{account.id} #{account.name}"
    end
  end

  it "fetches transactions given a date range" do
    account_id = ""

    account = @bank.find_account_by_id(account_id)
    expect(account.instance_variable_get(:@prior_day_balance)).to be_nil
    expect(account.instance_variable_get(:@current_balance)).to be_nil
    expect(account.instance_variable_get(:@available_balance)).to be_nil

    txns = @bank.fetch_transactions(account_id, Date.today - 30, Date.today)

    expect(txns.count).not_to equal(0)

    puts "Prior day balance: $#{account.prior_day_balance.to_f}"
    puts "Current balance: $#{account.current_balance.to_f}"
    puts "Available balance: $#{account.available_balance.to_f}"
    puts "Transaction count: #{txns.count}"

    expect(account.prior_day_balance).not_to be_nil
    expect(account.current_balance).not_to be_nil
    expect(account.available_balance).not_to be_nil
  end
end
