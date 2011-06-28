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
        ensure_authenticated

        # List accounts
        page = agent.get('https://banking.zionsbank.com/ibuir/displayAccountBalance.htm')
        json = ActiveSupport::JSON.decode(page.body)

        accounts = []
        json['accountBalance']['depositAccountList'].each do |account|
          new_account = Account.new(:id => account['accountId'])
          new_account.name = account['name']
          new_account.account_number = account['number']
          new_account.current_balance = parse_currency(account['currentAmt'])
          new_account.available_balance = parse_currency(account['availableAmt'])
          new_account.type = :deposit
          
          accounts << new_account
        end
        json['accountBalance']['creditAccountList'].each do |account|
          new_account = Account.new(:id => account['accountId'])
          new_account.name = account['name']
          new_account.account_number = account['number']
          new_account.current_balance = parse_currency(account['balanceDueAmt'])
          new_account.type = :credit
          
          accounts << new_account
        end

        accounts
      end
      
      def fetch_transactions(account_id, starting_at, ending_at)
        ensure_authenticated
        
        transactions = []
        
        post_vars = { "actAcct" => account_id, "dayRange.searchType" => "dates", "dayRange.startDate" => starting_at.strftime('%m/%d/%Y'), "dayRange.endDate" => ending_at.strftime('%m/%d/%Y'), "submit_view.x" => 11, "submit_view.y" => 11, "submit_view" => "view" }
        
        page = agent.post("https://banking.zionsbank.com/zfnb/userServlet/app/bank/user/register_view_main?reSort=false&actAcct=#{account_id}", post_vars)
        
        page.search('tr').each do |row_element|
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
        page = agent.get('https://banking.zionsbank.com/ibuir')
        if page.body.include?("SessionTimeOutException")
          
          raise InformationMissingError, "Please supply a username" unless self.username
          raise InformationMissingError, "Please supply a password" unless self.password
          
          @agent = Mechanize.new
          
          # Enter the username
          page = agent.get('https://zionsbank.com')
          form = page.form('logonForm')
          form.publicCred1 = username
          page = form.submit
          
          # If the supplied username is incorrect, raise an exception
          raise InformationMissingError, "Invalid username" if page.title == "Error Page"

          # Go on to the next page
          page = page.links.first.click

          # Find the secret question
          question = page.search('div.form_field')[2].css('div').inner_text
          
          # If the answer to this question was not supplied, raise an exception
          raise InformationMissingError, "Please answer the question, \"#{question}\"" unless secret_questions[question]
          
          # Enter the answer to the secret question
          form = page.forms.first
          form["challengeEntry.answerText"] = secret_questions[question]
          form.radiobutton_with(:value => 'false').check
          submit_button = form.button_with(:name => '_eventId_submit')
          page = form.submit(submit_button)
          
          # If the supplied answer is incorrect, raise an exception
          raise InformationMissingError, "\"#{secret_questions[question]}\" is not the correct answer to, \"#{question}\"" unless page.search('#errorComponent').empty?

          # Enter the password
          form = page.forms.first
          form.privateCred1 = password
          submit_button = form.button_with(:name => '_eventId_submit')
          page = form.submit(submit_button)
          
          # If the supplied password is incorrect, raise an exception
          raise InformationMissingError, "An invalid password was supplied" unless page.search('#errorComponent').empty?

          # Clicking this link logs us into the banking.zionsbank.com domain
          page = page.links.first.click
          
          raise "Unknown URL reached. Try logging in manually through a browser." if page.uri.to_s != "https://banking.zionsbank.com/ibuir/displayUserInterface.htm"
        end
        
        true
      end
      
    end
  end
end