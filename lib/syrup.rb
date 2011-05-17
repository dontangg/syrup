require 'date'
require 'mechanize'
require 'active_support/json'
require 'syrup/account'
require 'syrup/transaction'

# require all institutions
require 'syrup/institutions/abstract_institution'
Dir[File.dirname(__FILE__) + '/syrup/institutions/*.rb'].each {|file| require file }

module Syrup
  extend self
  
  def list_institutions
    Institutions::AbstractInstitution.subclasses.map do |subclass|
      subclass.institution_name
    end
  end
  
  def get_institution(institution_sym)
    class_name = institution_sym.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    Institutions.const_get(class_name).new
  end
end
