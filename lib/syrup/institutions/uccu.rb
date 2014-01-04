require 'date'
require 'bigdecimal'

module Syrup
  module Institutions
    class Uccu < InstitutionBase
      
      class << self
        def name
          "UCCU"
        end
        
        def id
          "uccu"
        end
      end
      
      def fetch_account(account_id)
        fetch_accounts
      end
      
      def fetch_accounts
        session_id = ensure_authenticated

        # List accounts
        page = agent.post('https://pb.uccu.com/UCCU/Ajax/RpcHandler.ashx',
                          '{"id":0,"method":"accounts.getBalances","params":[false]}',
                          'X-JSON-RPC' => 'accounts.getBalances')

        json = MultiJson.load(page.body)

        accounts = []
        json['result'].each do |account|
          next if account['accountIndex'] == -1
          
          new_account = Account.new(:id => account['accountIndex'], :institution => self)
          new_account.name = unescape_html(account['displayName'][/^[^(]*/, 0].strip)
          new_account.account_number = account['displayName'][/\(([*0-9-]+)\)/, 1]
          new_account.current_balance = BigDecimal.new(account['current'].to_s)
          new_account.available_balance = BigDecimal.new(account['available'].to_s)
          # new_account.type = :deposit # :credit
          
          accounts << new_account
        end

        accounts
      end
      
      def fetch_transactions(account_id, starting_at, ending_at)
        session_id = ensure_authenticated
        
        transactions = []

        # Get account
        account = find_account_by_id(account_id)
        
        # Get account current and available balances
        page = agent.post("https://pb.uccu.com/UCCU/af(#{session_id})/Services/Account/AccountService.svc/GetActivitySummaryTable",
                         "{\"accountIndex\":#{account_id}}", 
                         {"Content-Type" => "application/json; charset=UTF-8"})

        json = MultiJson.load(page.body)
        json['d']['DisplayItems'].each do |item|
          next if item["Name"] != "Available Balance:" && item["Name"] != "Current Balance:"
          if item["Name"] == "Current Balance:"
            account.current_balance = parse_currency(item["Value"])
          elsif item["Name"] == "Available Balance:"
            account.available_balance = parse_currency(item["Value"])
          end
        end

        # Get transactions
        page = agent.post("https://pb.uccu.com/UCCU/af(#{session_id})/Services/Transactions/TransactionService.svc/GetTransactions",
                          "{\"accountIndex\":#{account_id},\"startDate\":\"\/Date(#{starting_at.to_time.to_i.to_s + '000'})\/\",\"endDate\":\"\/Date(#{ending_at.to_time.to_i.to_s + '000'})\/\",\"categoryId\":null,\"subCategoryId\":null,\"transactionTypeId\":null}",
                          {"Content-Type" => "application/json; charset=UTF-8"}) 

        json = MultiJson.load(page.body)
        json['d']['Transactions'].each do |tran|
          transaction = Transaction.new

          date = tran['Date']
          if date.include?("-") || date.include?("+")
            transaction.posted_at = Date.strptime(date, '/Date(%Q%z)/')
          else
            transaction.posted_at = Date.strptime(date, '/Date(%Q)/')
          end

          transaction.payee = tran['Description']
          transaction.status = tran['IsPosted'] ? :posted : :pending
          transaction.amount = tran['IsDebit'] ? -tran['Amount'].to_d : tran['Amount'].to_d

          transactions << transaction
        end
        transactions
      end

      private
      
      def ensure_authenticated

        # Log in even if they are already logged in

        raise InformationMissingError, "Please supply a username" unless self.username
        raise InformationMissingError, "Please supply a password" unless self.password

        @agent = nil # Mechanize.new

        # Get the login page
        page = agent.get('https://pb.uccu.com/UCCU/Login.aspx')
        form = page.form('MAINFORM')

        # Enter the username
        form.field_with(:id => 'ctlSignonWorkflow_txtUserID').value = username
        form.TestJavaScript = 'OK'
        login_button = form.button_with(:name => 'ctlSignonWorkflow$btnLogin')
        page = form.submit(login_button)

        # Enter the password & go to Account Activity
        form = page.form('MAINFORM')
        form.field_with(:id => 'ctlSignonWorkflow_txtPassword').value = password
        form.field_with(:id => 'ctlSignonWorkflow_ddlSignonDestination').value = 'Accounts.Activity'
        form.TestJavaScript = 'OK'
        login_button = form.button_with(:name => 'ctlSignonWorkflow$btnLoginUser')
        page = form.submit(login_button)

        # If the supplied username/password is incorrect, raise an exception
        raise InformationMissingError, "Invalid username or password" if page.body.include?("We are unable to validate your information")

        # Secret questions???
        if page.body.include?("For security purposes, please validate your identity by answering the following question:") 
          form = page.form('MAINFORM')
          form.field_with(:id => 'txtAnswer').value = secret_questions[page.search('#lblChallengeQuestion').inner_text]
          submit_button = form.button_with(:name => 'btnSubmitAnswer')
          page = form.submit(submit_button)
        end

        # File.open("C:\\users\\reed.wilson\\desktop\\html_tst.html", 'w') { |file| file.write(page.body) }
        
        # Get session id
        return page.uri.to_s.scan(/af\((\w+)\)/)[0][0]

        # if page.body.include?("Please enter your User ID and Password below.") || page.body.include?("Your Online Banking session has expired.")
        #   raise "Unknown URL reached. Try logging in manually through a browser." 
        # end

        # true
      end
    end
  end
end
