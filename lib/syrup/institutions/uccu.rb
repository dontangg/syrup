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
        []
      end
      

      def fetch_transactions(account_id, starting_at, ending_at)
        acct_id, registration_cookie = account_id.split('|')
        ensure_authenticated(registration_cookie)
        # put the current and available balances on the account
        populate_account_balances(acct_id)
        transactions = []
        start_at = format_date(starting_at)
        end_at= format_date(ending_at)
        url = "https://online.uccu.com/ucfcuonline_42/mobilews/accountHistory/#{acct_id}/1/300?postedDate=#{start_at}%1F#{end_at}"
        page = get_page(url)
        body = MultiJson.load(page.body)
        # Get all the transactions
        body['data']['transactions'].each do |tran|
          transaction = Transaction.new
          transaction.posted_at = DateTime.parse(tran['postedDate'])
          transaction.payee = tran['description']
          transaction.status = :posted
          transaction.amount = tran['extended']['signedTxnAmount'].to_d
          transactions << transaction
        end
        transactions
      end


      private


      def populate_account_balances(account_id)
        url = "https://online.uccu.com/ucfcuonline_42/mobilews/account/#{account_id}"
        page = get_page(url)
        account = find_account_by_id(account_id)
        body = MultiJson.load(page.body)
        body['data']['dataElements'].each do |elem|
          if elem['hadeName'] == 'AvailBal'
            account.available_balance = parse_currency(elem['value'])
          elsif elem['hadeName'] == 'CurBal'
            account.current_balance = parse_currency(elem['value'])
          end
        end
      end 


      def get_page(url)
        agent.get(url, [], nil, {
          'Cookie' => @cookie,
          'x-csrf' => @csrf
        })
      end


      def ensure_authenticated(registration_cookie)
        # Log in even if they are already logged in
        raise InformationMissingError, "Please supply a username" unless self.username
        raise InformationMissingError, "Please supply a password" unless self.password
        # Get the login page
        url = 'https://online.uccu.com/ucfcuonline_42/mobilews/logonUser'
        data = "{\"userId\": \"#{self.username}\",\"password\": \"#{self.password}\"}"
        headers = {
          'Cookie' => "#{registration_cookie}",
          'Content-Type' => "application/json; charset=UTF-8" 
        }
        page = agent.post(url, data, headers)
        cookie_header = page.response['set-cookie']
        # If the supplied username/password is incorrect, raise an exception
        raise InformationMissingError, "Invalid username or password" if !page.code=("200")
        @cookie = build_cookie(cookie_header, registration_cookie)
        @csrf = MultiJson.load(page.body)['data']['token']
        # File.open("~/testpage", 'w') { |file| file.write(page.body) }
      end


      def format_date(date)
        date.strftime('%D')
      end


      def build_cookie(set_cookie, registration_cookie)
        cookies = []
        for c in set_cookie.split(',')
          cookies << c.split(';')[0]
        end
        cookie = cookies.join(';')
        return "#{registration_cookie}; #{cookie}"
      end
    end
  end
end
