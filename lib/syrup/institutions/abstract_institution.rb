module Syrup
  module Institutions
    class AbstractInstitution
      
      def self.inherited(subclass)
        @subclasses ||= []
        @subclasses << subclass
      end
      
      def self.subclasses
        @subclasses
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