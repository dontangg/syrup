module Syrup
  module Institutions
    class ZionsBank < Base
      
      class << self
        def name
          "Zions Bank"
        end
        
        def id
          "zions_bank"
        end
      end
      
      def fetch_accounts
        ensure_authenticated

        # List accounts
        page = agent.get('https://banking.zionsbank.com/ibuir/displayAccountBalance.htm')
        json = ActiveSupport::JSON.decode(page.body)

        accounts = []
        json['accountBalance']['depositAccountList'].each do |account|
          new_account = Account.new
          new_account.name = account['name']
          new_account.id = account['accountId']
          new_account.account_number = account['number']
          new_account.current_balance = parse_currency(account['currentAmt'])
          new_account.available_balance = parse_currency(account['availableAmt'])
          new_account.type = :deposit
          
          accounts << new_account
        end
        json['accountBalance']['creditAccountList'].each do |account|
          new_account = Account.new
          new_account.name = account['name']
          new_account.id = account['accountId']
          new_account.account_number = account['number']
          new_account.current_balance = parse_currency(account['balanceDueAmt'])
          new_account.type = :credit
          
          accounts << new_account
        end

        accounts
      end
      
      def fetch_transactions
        ensure_authenticated
        
        # https://banking.zionsbank.com/zfnb/userServlet/app/bank/user/register_view_main?actAcct=498282&sortBy=Default&sortOrder=Default

        # The transactions table is messy. Cells we want either have data, curr, datagrey, or currgrey css class
      end
      
      private
      
      def ensure_authenticated
        
        # Check to see if already authenticated
        page = agent.get('https://banking.zionsbank.com/ibuir')
        if page.body.include?("SessionTimeOutException")
          
          raise ArgumentError, "Username must be supplied before authenticating" unless self.username
          raise ArgumentError, "Password must be supplied before authenticating" unless self.password
          
          @agent = Mechanize.new
          
          # Enter the username
          page = agent.get('https://zionsbank.com')
          form = page.form('logonForm')
          form.publicCred1 = username
          page = form.submit
          
          # If the supplied username is incorrect, raise an exception
          raise "Invalid username" if page.title == "Error Page"

          # Go on to the next page
          page = page.links.first.click

          # Find the secret question
          question = page.search('div.form_field')[2].css('div').inner_text
          
          # If the answer to this question was not supplied, raise an exception
          raise question unless secret_qas[question]
          
          # Enter the answer to the secret question
          form = page.forms.first
          form["challengeEntry.answerText"] = secret_qas[question]
          form.radiobutton_with(:value => 'false').check
          submit_button = form.button_with(:name => '_eventId_submit')
          page = form.submit(submit_button)
          
          # If the supplied answer is incorrect, raise an exception
          raise "Invalid answer" unless page.search('#errorComponent').empty?

          # Enter the password
          form = page.forms.first
          form.privateCred1 = password
          submit_button = form.button_with(:name => '_eventId_submit')
          page = form.submit(submit_button)
          
          # If the supplied password is incorrect, raise an exception
          raise "Invalid password" unless page.search('#errorComponent').empty?

          # Clicking this link logs us into the banking.zionsbank.com domain
          page = page.links.first.click
          
        end
        
        true
      end
      
    end
  end
end