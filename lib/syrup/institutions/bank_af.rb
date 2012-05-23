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
          populate_account_from_cells(new_account, cells)

          accounts << new_account
        end

        accounts
      end

      def populate_account_from_cells(account, cells)
        account.id = cells[1].inner_text.strip
        account.name = account.id
        # account.account_number = 
        account.current_balance = BigDecimal.new(parse_currency(cells[2].inner_text))
        account.available_balance = account.current_balance
        # account.type = :deposit # :credit
      end

      def write_page(page, unique)
        File.open("test#{unique}.html", 'w') do |f|
          f.write page.uri.to_s
          f.write page.body
        end
      end

      def get_event_target(html)
        match = /doPostBack\('([^'"]+)'/.match(html)
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
            account = find_account_by_id(account_id)
            populate_account_from_cells(account, cells)
            event_target = get_event_target(cells[1].inner_html)
          end
        end
        raise InformationMissingError, "Invalid account ID: #{account_id}" unless event_target
        form["__EVENTTARGET"] = event_target
        page = form.submit

        # Click the search button (we want to be able to specify a date range)
        form = page.form('aspnetForm')
        form["__EVENTTARGET"] = "ctl00$ctl14$retailTransactionsTertiaryMenuSearchMenuItemLinkButton"
        page = form.submit

        # Tranferring to Coldfusion
        form = page.forms[0]
        form.action = "https://www.netteller.com/bankaf/hbTransactionsSelect.cfm"
        page = form.submit

        # Submitting the search form
        form = page.forms[0]
        form["from"] = starting_at.strftime('%m/%d/%Y')
        form["to"] = ending_at.strftime('%m/%d/%Y')
        form["sortField1"] = "D"
        form["CreditsDebits"] = "CreditsAndDebits"
        form.radiobutton_with(:name => "DescendingOrderFlag", :value => 'D').check
        form.checkbox_with(:name => "ChecksFlag").check
        form.checkbox_with(:name => "ElecTxnsFlag").check
        form.field_with(:name => 'AccountIndex').options.each do |option|
          option.select if option.text.strip == account_id
        end
        page = form.submit
        
        # Go back to .NET
        form = page.forms[0]
        page = form.submit

        # Get the transactions!
        transactions = []
        page_number = 1
        has_more_pages = true

        while has_more_pages
          page.search('#ctl00_PageContent_ctl00__transBase__tab__transactionsDataGrid tr').each do |row_element|
            next if row_element["class"] == "th" || row_element["class"] == "Total"

            cells = row_element.css('td')

            if row_element["class"] == "pager"
              # Check for more pages of transactions
              page_number += 1
              has_more_pages = false
              cells[0].css('a').each do |link|
                if link.inner_text.strip == page_number.to_s
                  event_target = get_event_target(link.to_html)
                  form = page.forms[0]
                  form["__EVENTTARGET"] = event_target
                  page = form.submit
                  has_more_pages = true
                end
              end 
            else
              cells = cells.to_a.map! { |cell| cell.inner_text.strip }

              if !cells[0].empty?
                txn = Transaction.new

                txn.posted_at = Date.strptime(cells[0], '%m/%d/%Y')
                txn.payee = unescape_html(cells[3])
                if cells[5].include?('$')
                  txn.amount = parse_currency(cells[5])
                elsif cells[8].include?('$')
                  txn.amount = parse_currency(cells[8])
                end
                running_balance = parse_currency(cells[10])
                txn.status = :posted

                transactions << txn
              end
            end
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
