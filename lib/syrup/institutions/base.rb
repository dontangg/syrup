module Syrup
  module Institutions
    class Base
      
      def self.inherited(subclass)
        @subclasses ||= []
        @subclasses << subclass
      end
      
      def self.subclasses
        @subclasses
      end
      
      attr_reader :username, :password, :secret_questions
      
      def initialize(username, password, secret_questions)
        @username, @password = username, password
        @secret_questions = secret_questions
      end
      
      protected
      
      def agent
        @agent ||= Mechanize.new
      end
        
      def parse_currency(currency)
        currency.scan(/[0-9.]/).join.to_f
      end
      
    end
  end
end