require 'date'
require 'bigdecimal'

module Syrup
  module Institutions
    class BankAf < InstitutionBase

      class << self
        def name
          "Bank of American Fork"
        end

        def id
          "bank_af"
        end
      end

      def fetch_account(account_id)
        fetch_accounts
      end

      def fetch_accounts
        ensure_authenticated

        # List accounts
        page = agent.get('https://cm.netteller.com/login2008/Views/Retail/AccountListing.aspx')

        accounts = []
        page.search('#ctl00_PageContent_ctl00__acctsBase__depositsTab__depositsGrid tr').each do |row_element|
          next if row_element["class"] == "th"

          cells = row_element.css('td')

          new_account = Account.new(:institution => self)

          new_account.name = cells[1].inner_text.strip
          #new_account.account_number = 
          new_account.current_balance = BigDecimal.new(parse_currency(cells[2].inner_text))
          #new_account.available_balance = 
          # new_account.type = :deposit # :credit

          accounts << new_account
        end

        accounts
      end

      def fetch_transactions(account_id, starting_at, ending_at)
        ensure_authenticated

        transactions = []
        #TranDays=&From=4%2F01%2F2012&To=4%2F30%2F2012&BeginAmount=0000000000000&EndAmount=0000000000000&StartCheckNumber=&EndCheckNumber=&sortField1=D&sortField2=&sortField3=&sortField4=&DescendingOrderFlag=D&CreditsFlag=Y&DebitsFlag=Y&ChecksFlag=Y&ElecTxnsFlag=Y&CurrentOrRange=Range
        params = {'TranDays' => nil, 'From' => starting_at.strftime('%e/%d/%Y'), 'To' => ending_at.strftime('%e/%d/%Y'), 'BeginAmount' => '0000000000000', 'EndAmount' => '0000000000000', 'StartCheckNumber' => nil, 'EndCheckNumber' => nil, 'sortField1' => 'D', 'sortField2' => nil, 'sortField3' => nil, 'sortField4' => nil, 'DescendingOrderFlag' => 'D', 'CreditsFlag' => 'Y', 'DebitsFlag' => 'Y', 'ChecksFlag' => 'Y', 'ElecTxnsFlag' => 'Y', 'CurrentOrRange' => 'Range' }
        page = agent.get("https://www.netteller.com/bankaf/hbAccountDetails.cfm?", params)


        File.open('test.html', 'w') do |f|
          f.write page.uri.to_s
          f.write page.body
        end

        page = page.forms[0].submit

        form.ddlAccounts = account_id
        form.ddlType = 0 # 0 = All types of transactions
        form.field_with(:id => 'txtFromDate_textBox').value = starting_at.month.to_s + '/' + starting_at.strftime('%e/%Y').strip
        form.field_with(:id => 'txtToDate_textBox').value = ending_at.month.to_s + '/' + ending_at.strftime('%e/%Y').strip
        submit_button = form.button_with(:name => 'btnSubmitHistoryRequest')
        page = form.submit(submit_button)

        # Look for the account balance
        account = find_account_by_id(account_id)
        page.search('.summaryTable tr').each do |row_element|
          first_cell_text = ''
          row_element.children.each do |cell_element|
            if first_cell_text.empty?
              first_cell_text = cell_element.content.strip if cell_element.respond_to? :name
            else
              content = cell_element.content.strip
              case first_cell_text
              when "Available Balance:"
                account.available_balance = parse_currency(content) if content.match(/\d+/)
              when "Current Balance:"
                account.current_balance = parse_currency(content) if content.match(/\d+/)
              end
            end
          end
        end

        # Get all the transactions
        page.search('#ctlAccountActivityChecking tr').each do |row_element|
          next if row_element['class'] == 'header'

          data = row_element.css('td').map {|element| element.content.strip }

          transaction = Transaction.new
          transaction.posted_at = Date.strptime(data[0], '%m/%d/%Y')
          transaction.payee = unescape_html(data[3])
          transaction.status = :posted # :pending
          transaction.amount = -parse_currency(data[4]) if data[4].match(/\d+/)
          transaction.amount = parse_currency(data[5]) if data[5].match(/\d+/)

          transactions << transaction
        end

        transactions
      end

      private

      def ensure_authenticated

        # Check to see if already authenticated
        page = agent.get('https://cm.netteller.com/login2008/Views/Retail/AccountListing.aspx')
        if page.body.include?("An Error Occurred While Processing Your Request")

          raise InformationMissingError, "Please supply a username" unless self.username
          raise InformationMissingError, "Please supply a password" unless self.password

          # Enter the username and password
          login_vars = { 'ID' => username, 'PIN' => password }
          page = agent.post('https://cm.netteller.com/login2008/Authentication/Views/Login.aspx?fi=bankaf&bn=9de8ca724dd43418&burlid=dc1ba449ca4ad5c0', login_vars)

          # If the supplied username/password is incorrect, raise an exception
          raise InformationMissingError, "Invalid username or password" if page.body.include?("Invalid Online Banking ID or Password")

          form = page.forms[0]
          form["ctl00$PageContent$DevicePrintHiddenField"] = "version=1&pm_fpua=mozilla/5.0 (macintosh; intel mac os x 10.7; rv:11.0) gecko/20100101 firefox/11.0|5.0 (Macintosh)|MacIntel&pm_fpsc=24|1280|800|774&pm_fpsw=&pm_fptz=-6&pm_fpln=lang=en-US|syslang=|userlang=&pm_fpjv=1&pm_fpco=1"
          page = form.submit

          if page.uri.to_s == "https://cm.netteller.com/login2008/Authentication/Views/ChallengeQuestions.aspx"
            form = page.forms[0]
            question1 = page.search('#ctl00_PageContent_Question1Label').inner_text
            form["ctl00$PageContent$Answer1TextBox"] = secret_questions[question1]

            question2 = page.search('#ctl00_PageContent_Question2Label').inner_text
            form["ctl00$PageContent$Answer2TextBox"] = secret_questions[question2]

            submit_button = form.button_with(:name => 'ctl00$PageContent$SubmitButton')

            page = form.submit(submit_button)

            # TODO: What if the secret questions' answers were incorrect
          end

          form = page.forms[0]
          form.action = "https://cm.netteller.com/login2008/Default.aspx"
          page = form.submit

          # TODO: find a better way to test success
          raise "Unknown URL reached. Try logging in manually through a browser." if page.uri.to_s != "https://cm.netteller.com/login2008/Views/Retail/AccountListing.aspx"
        end

        true
      end

    end
  end
end
