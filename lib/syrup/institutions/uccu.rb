require 'date'

# Net::HTTP::Persistent::Error: too many connection resets (due to An established connection was aborted by the software i
# n your host machine. - Errno::ECONNABORTED) after 2 requests on 24106116
        #from C:/Ruby192/lib/ruby/gems/1.9.1/gems/net-http-persistent-1.8/lib/net/http/persistent.rb:446:in `rescue in re
#quest'
        #from C:/Ruby192/lib/ruby/gems/1.9.1/gems/net-http-persistent-1.8/lib/net/http/persistent.rb:422:in `request'
        #from C:/Ruby192/lib/ruby/gems/1.9.1/gems/mechanize-2.0.1/lib/mechanize/http/agent.rb:204:in `fetch'
        #from C:/Ruby192/lib/ruby/gems/1.9.1/gems/mechanize-2.0.1/lib/mechanize.rb:539:in `request_with_entity'
        #from C:/Ruby192/lib/ruby/gems/1.9.1/gems/mechanize-2.0.1/lib/mechanize.rb:485:in `post'
        #from (irb):16
        #from C:/Ruby192/bin/irb:12:in `<main>'

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
        ensure_authenticated

        # List accounts
        page = agent.post('https://pb.uccu.com/UCCU/Ajax/RpcHandler.ashx', '{"id":0,"method":"accounts.getBalances","params":[false]}', 'X-JSON-RPC' => 'accounts.getBalances')
        json = MultiJson.decode(page.body)

        accounts = []
        json['result'].each do |account|
          next if account['accountIndex'] == -1
          
          new_account = Account.new(:id => account['accountIndex'])
          new_account.name = account['displayName']
          new_account.account_number = /\(([*0-9-]+)\)/.match(account['displayName'])[1]
          new_account.current_balance = account['current'].to_f
          new_account.available_balance = account['available'].to_f
          # new_account.type = :deposit # :credit
          
          accounts << new_account
        end

        accounts
      end
      
      def fetch_transactions(account_id, starting_at, ending_at)
        ensure_authenticated
        
        transactions = []
        
        post_vars = { "actAcct" => account_id, "dayRange.searchType" => "dates", "dayRange.startDate" => starting_at.strftime('%m/%d/%Y'), "dayRange.endDate" => ending_at.strftime('%m/%d/%Y'), "submit_view.x" => 11, "submit_view.y" => 11, "submit_view" => "view" }
        
        page = agent.post("https://banking.zionsbank.com/zfnb/userServlet/app/bank/user/register_view_main?reSort=false&actAcct=#{account_id}", post_vars)
        
        # Get all the transactions
        page.search('tr').each do |row_element|
          # Look for the account information first
          account = find_account_by_id(account_id)
          datapart = row_element.css('.acct')
          if datapart
            /Prior Day Balance:\s*([^<]+)/.match(datapart.inner_html) do |match|
              account.prior_day_balance = parse_currency(match[1])
            end
            /Current Balance:\s*([^<]+)/.match(datapart.inner_html) do |match|
              account.current_balance = parse_currency(match[1])
            end
            /Available Balance:\s*([^<]+)/.match(datapart.inner_html) do |match|
              account.available_balance = parse_currency(match[1])
            end
          end
        
          data = []
          datapart = row_element.css('.data')
          if datapart
            data += datapart
            datapart = row_element.css('.curr')
            data += datapart if datapart
          end
          
          datapart = row_element.css('.datagrey')
          if datapart
            data += datapart
            datapart = row_element.css('.currgrey')
            data += datapart if datapart
          end
          
          if data.size == 7
            data.map! {|cell| cell.inner_html.strip.gsub(/[^ -~]/, '') }
            
            transaction = Transaction.new

            transaction.posted_at = Date.strptime(data[0], '%m/%d/%Y')
            transaction.payee = data[2]
            transaction.status = data[3].include?("Posted") ? :posted : :pending
            unless data[4].empty?
              transaction.amount = -parse_currency(data[4])
            end
            unless data[5].empty?
              transaction.amount = parse_currency(data[5])
            end
            
            transactions << transaction
          end
        end
        
        transactions
      end
      
      private
      
      def ensure_authenticated
        
        # Check to see if already authenticated
        page = agent.get('https://pb.uccu.com/UCCU/Accounts/Activity.aspx')
        if page.body.include?("Please enter your User ID and Password below.") || page.body.include?("Your Online Banking session has expired.")
          
          raise InformationMissingError, "Please supply a username" unless self.username
          raise InformationMissingError, "Please supply a password" unless self.password
          
          @agent = Mechanize.new
          
          # Enter the username
          page = agent.get('https://pb.uccu.com/UCCU/Login.aspx')
          form = page.form('MAINFORM')
          form.field_with(:id => 'ctlSignon_txtUserID').value = username
          form.field_with(:id => 'ctlSignon_txtPassword').value = password
          form.field_with(:id => 'ctlSignon_ddlSignonDestination').value = 'Accounts.Overview'
          form.TestJavaScript = 'OK'
          login_button = form.button_with(:name => 'ctlSignon:btnLogin')
          page = form.submit(login_button)
          
          # If the supplied username/password is incorrect, raise an exception
          raise InformationMissingError, "Invalid username or password" if page.body.include?("Login not accepted.") || page.body.include?("Please enter a valid signon ID.") || page.body.include?("Please enter a valid Password.")

          # Secret questions???
          
          raise "Unknown URL reached. Try logging in manually through a browser." if page.uri.to_s != "https://pb.uccu.com/UCCU/Accounts/Overview.aspx"
        end
        
        true
      end
      
    end
  end
end