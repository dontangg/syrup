require 'date'

module Syrup
  module Institutions
    class ZionsBank < InstitutionBase

      class << self
        def name
          "Zions Bank"
        end

        def id
          "zions_bank"
        end
      end

      def fetch_account(account_id)
        fetch_accounts
      end

      def fetch_accounts
        # TODO: If I ever care about this, I'll add it in later.  This is the url to grab from:
        # https://banking.zionsbank.com/olb/retail/protected/myBank/balances?OWASP_CSRFTOKEN=
        #
        #ensure_authenticated
        #
        # List accounts
        #page = agent.get('https://banking.zionsbank.com/ibuir/displayAccountBalance.htm')
        #json = MultiJson.load(page.body)

        #accounts = []
        #json['accountBalance']['depositAccountList'].each do |account|
        #  new_account = Account.new(:id => account['accountId'], :institution => self)
        #  new_account.name = unescape_html(account['name'])
        #  new_account.account_number = account['number']
        #  new_account.current_balance = parse_currency(account['currentAmt'])
        #  new_account.available_balance = parse_currency(account['availableAmt'])
        #  new_account.type = :deposit

        #  accounts << new_account
        #end
        #json['accountBalance']['creditAccountList'].each do |account|
        #  new_account = Account.new(:id => account['accountId'], :institution => self)
        #  new_account.name = unescape_html(account['name'])
        #  new_account.account_number = account['number']
        #  new_account.current_balance = parse_currency(account['balanceDueAmt'])
        #  new_account.type = :credit

        #  accounts << new_account
        #end

        #accounts

        []
      end

      def fetch_transactions(account_id, starting_at, ending_at)
        ensure_authenticated

        transactions = []

        account_id = "679793|aWQ9Njc5Nzkz"
        act_oid, act_attr = account_id.split('|')

        url = "https://banking.zionsbank.com/olb/retail/protected/account/register/account?attr=#{act_attr}&#{@csrf}"
        page = agent.get(url)

        form = page.forms.first
        form.action += "?#{@csrf}" unless form.action.include?(@csrf)
        form["accountOid"] = act_oid
        form["searchBy"] = "DR"
        form['fromDate'] = starting_at.strftime('%m/%d/%Y')
        form['toDate'] = ending_at.strftime('%m/%d/%Y')
        submit_button = form.button_with(:id => 'formbutton')
        puts "submitting..."
        page = form.submit(submit_button)

        // if #pagination isn't there, then there aren't any more pages

        #File.open("page.html", 'w') { |file| file.write(page.body) }
        #puts "written"

        # Look for the account information first
        account = find_account_by_id(account_id)
        page.search('#subCell').first.element_children.each do |element|
          if element.name == "div"
            #p "\n#{element.inner_text}\n"
            if match = /Prior Day Balance:\s*\$([0-9.,]+)/.match(element.inner_text)
              account.prior_day_balance = parse_currency(match[1])
              p account.prior_day_balance.to_f
            elsif match = /Current Balance:\s*\$([0-9.,]+)/.match(element.inner_text)
              account.current_balance = parse_currency(match[1])
              p account.current_balance.to_f
            elsif match = /Available Balance:\s*\$([0-9.,]+)/.match(element.inner_text)
              account.available_balance = parse_currency(match[1])
              p account.available_balance.to_f
            end
          end
        end

        # Get all the transactions
        page.search('#RegisterCntBox .list_table tr').each do |row_element|
          account = find_account_by_id(account_id)



          date_cell = row_element.search('.table_column_0').first
          if date_cell
            transaction = Transaction.new

            transaction.posted_at = Date.strptime(date_cell.inner_text.strip, '%m/%d/%Y')

            payee_cell = row_element.search('.table_column_2 .printdisplay .changeText').first || row_element.search('.table_column_2').first
            transaction.payee = payee_cell.inner_text.strip

            p transaction

            transactions << transaction
          end

          #transaction.payee = unescape_html(data[2])
          #transaction.status = data[3].include?("Posted") ? :posted : :pending
          #unless data[4].empty?
          #  transaction.amount = -parse_currency(data[4])
          #end
          #unless data[5].empty?
          #  transaction.amount = parse_currency(data[5])
          #end

        end

        transactions
      end

      private

      def ensure_authenticated

        # We no longer have a way to check to see if we're logged in or not... assume we're not.

        raise InformationMissingError, "Please supply a username" unless self.username
        raise InformationMissingError, "Please supply a password" unless self.password

        # Enter the username
        page = agent.get('https://www.zionsbank.com')
        form = page.form('logonForm')
        form.publicCred1 = self.username
        form.privateCred1 = self.password
        page = form.submit

        # If the supplied username is incorrect, raise an exception
        # In my tests, invalid username takes you to the password page and an invalid password takes you to the error page
        raise InformationMissingError, "Invalid username/password" if page.title == "Password Page" || page.title == "Error Page"

        # Go on to the next page
        # It is something like this: https://banking.zionsbank.com/olb/retail/logon/mfa/sso?SAMLart=<bigLongKey>
        page = page.links.first.click

        #refresh = page.body.match /meta http-equiv="Refresh" content="0; url=([^"]+)/
        #if refresh
        #  url = refresh[1]
        #  page = agent.get("https://securentry.zionsbank.com#{url}")
        #end

        # TODO: figure out how this is supposed to work now
        # Skip the secret question if we are prompted for the password
        #unless page.body.include?("Site Validation and Password")
        #  # Find the secret question
        #  question = page.search('div.form_field')[2].css('div').inner_text
        #
        #  # If the answer to this question was not supplied, raise an exception
        #  raise InformationMissingError, "Please answer the question, \"#{question}\"" unless secret_questions && secret_questions[question]
        #
        #  # Enter the answer to the secret question
        #  form = page.forms.first
        #  form["challengeEntry.answerText"] = secret_questions[question]
        #  form.radiobutton_with(:value => 'false').check
        #  submit_button = form.button_with(:name => '_eventId_submit')
        #  page = form.submit(submit_button)
        #
        #  # If the supplied answer is incorrect, raise an exception
        #  raise InformationMissingError, "\"#{secret_questions[question]}\" is not the correct answer to, \"#{question}\"" unless page.search('#errorComponent').empty?
        #end

        if !page.uri.to_s.start_with?("https://banking.zionsbank.com/olb/retail/protected/home")
          raise "Unknown URL reached. Try logging in manually through a browser."
        end

        token_name = page.search('#csrfTokenName').text
        token_value = page.search('#csrfTokenValue').text

        @csrf = "#{token_name}=#{token_value}"

        puts "Logged in!"

        true
      end

    end
  end
end
