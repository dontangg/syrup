require 'date'
require 'bigdecimal'
require 'bigdecimal/util'
require 'csv'

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
          new_account.id = cells[1].inner_text.strip
          new_account.name = new_account.id
          new_account.available_balance = BigDecimal.new(parse_currency(cells[2].inner_text))
          # new_account.current_balance = 
          # new_account.account_number = 
          # new_account.type = :deposit # :credit

          accounts << new_account
        end

        accounts
      end

      def write_page(page, unique)
        File.open("test#{unique}.html", 'w') do |f|
          f.write page.uri.to_s
          f.write page.body
        end
      end

      def get_event_target(html)
        match = /doPostBack\('([^'"\\]+)'/.match(html)
                             match[1].gsub(/%24/, '$')
      end

      def fetch_transactions(account_id, starting_at, ending_at)
        ensure_authenticated

        # Get the accounts page and click on the desired account link
        page = agent.get('https://cm.netteller.com/login2008/Views/Retail/AccountListing.aspx')

        form = page.form('aspnetForm')
        event_target = nil
        page.search('#ctl00_PageContent_ctl00__acctsBase__depositsTab__depositsGrid tr').each do |row_element|
          next if row_element["class"] == "th"

          cells = row_element.css('td')

          if cells[1].inner_text.strip == account_id
            event_target = cells[4].css('select')[0]["name"]
          end
        end
        raise InformationMissingError, "Invalid account ID: #{account_id}" unless event_target
        form["__EVENTTARGET"] = event_target
        form.field_with(:name => 'ctl00$PageContent$ctl00$_acctsBase$_depositsTab$_depositsGrid$ctl02$_activity').option_with(:value => "TransactionDownloadViewAction").select
        page = form.submit

        # Tranferring to Coldfusion
        form = page.forms[0]
        form.action = "https://www.netteller.com/bankaf/hbProcessRequest.cfm?activity=D"
        page = form.submit

        # Submit the download request form
        form = page.forms[0]
        form.field_with(:name => 'AccountIndex').option_with(:text => account_id).select
        form.field_with(:name => 'trans').option_with(:value => 'BetweenTwoDates').select
        form.field_with(:name => 'format').option_with(:value => 'QFX').select
        form["from"] = starting_at.strftime('%m/%d/%Y')
        form["to"] = ending_at.strftime('%m/%d/%Y')
        submit_button = form.button_with(:id => 'submitButton')
        page = form.submit(submit_button)

        page = page.link_with(:href => /DeliverContent/).click

        # Get the transactions!
        transactions = []
        account = find_account_by_id(account_id)
        page.body.each_line do |line|
          line.strip!

          if line.start_with?("<STMTTRN>")
            match = /DTPOSTED>(\d+)<TRNAMT>\s?([0-9.-]+).*NAME>([^<]+)/.match(line)
            txn = Transaction.new

            txn.posted_at = Date.strptime(match[1][0..7], '%Y%m%d')
            txn.amount = parse_currency(match[2])
            txn.payee = match[3].strip
            txn.status = :posted

            transactions << txn
          elsif line.start_with?("</BANKTRANLIST>")
            match = /LEDGERBAL><BALAMT>([0-9.-]+).*AVAILBAL><BALAMT>([0-9.-]+)/.match(line)
            account.name = account.id
            account.current_balance = match[1].to_d
            account.available_balance = match[2].to_d
          end
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
            #write_page(page, 'sq')
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
