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

        act_oid, act_attr = account_id.split('|')
        timestamp = Time.new.to_i

        url = "https://banking.zionsbank.com/olb/retail/protected/account/register/search?#{@csrf}&atstamp=#{timestamp}"
        page = agent.post(url, {
          "accountOid" => act_oid,
          "HFromDate" => starting_at.strftime('%m/%d/%Y'),
          "HToDate" => ending_at.strftime('%m/%d/%Y'),
          "fromDate" => starting_at.strftime('%m/%d/%Y'),
          "toDate" => ending_at.strftime('%m/%d/%Y'),
          "searchBy" => "DR",
          "fromCheckNum" => "",
          "toCheckNum" => "",
          "keyword" => "",
          "fromAmount" => "",
          "toAmount" => "",
          "transactionsByDepositOrWithdrawalAmount" => "deposits",
          "sortBy" => "date",
          "sortOrder" => "dsc"
        })

        # Look for the account information first
        account = find_account_by_id(account_id)
        page.search('#subCell').first.element_children.each do |element|
          if element.name == "div"
            if match = /Prior Day Balance:\s*\$([0-9.,]+)/.match(element.inner_text)
              account.prior_day_balance = parse_currency(match[1])
            elsif match = /Current Balance:\s*\$([0-9.,]+)/.match(element.inner_text)
              account.current_balance = parse_currency(match[1])
            elsif match = /Available Balance:\s*\$([0-9.,]+)/.match(element.inner_text)
              account.available_balance = parse_currency(match[1])
            end
          end
        end

        # File.write('/Users/don/Desktop/page.html', page.body)

        # Get all the transactions
        include_pending = true
        begin
          transactions += get_transactions_from_page(page, include_pending)

          has_next_page = false
          pagination_div = page.search('#pagination').first
          if pagination_div # if #pagination isn't there, then there aren't any more pages
            next_page_link = pagination_div.search('.prevnext').last
            if next_page_link.inner_text.strip.downcase == 'next'
              url = "#{next_page_link['href']}&#{@csrf}"
              page = agent.get(url)
              has_next_page = true
              include_pending = false # The pending txns are included on every page, so don't get them again when we switch pages
            end
          end
        end while has_next_page

        transactions
      end

      def get_value(value)
        value.gsub("\u00A0", " ").strip
      end

      def get_transactions_from_page(page, include_pending)
        transactions = []

        page.search('#RegisterCntBox .list_table tr').each do |row_element|

          date_cell = row_element.search('.table_column_0').first
          if date_cell
            date_cell_text = get_value(date_cell.inner_text)
            next if date_cell_text.empty?

            status_image = row_element.search('.table_column_3 img').first
            status = status_image['alt'] == 'Cleared' ? :posted : :pending
            next unless status == :posted || include_pending

            transaction = Transaction.new

            transaction.posted_at = Date.strptime(date_cell_text, '%m/%d/%Y')

            payee_cell = row_element.search('.table_column_2 .printdisplay .changeText').first || row_element.search('.table_column_2').first
            transaction.payee = get_value(payee_cell.inner_text)

            transaction.status = status

            debit_amount_cell = row_element.search('.table_column_4').first
            debit_amount = get_value(debit_amount_cell.inner_text)
            unless debit_amount.empty?
              transaction.amount = -parse_currency(debit_amount)
            end

            credit_amount_cell = row_element.search('.table_column_5').first
            credit_amount = get_value(credit_amount_cell.inner_text)
            unless credit_amount.empty?
              transaction.amount = parse_currency(credit_amount)
            end

            transactions << transaction
          end

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
        form = page.form_with(id: 'personalForm')
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

        true
      end

    end
  end
end
