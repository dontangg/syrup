require 'date'
require 'mechanize'
require 'active_support/json'
require 'syrup/account'
require 'syrup/transaction'

# require all institutions
require 'syrup/institutions/institution_base'
Dir[File.dirname(__FILE__) + '/syrup/institutions/*.rb'].each {|file| require file }

module Syrup
  extend self
  
  def institutions
    Institutions::InstitutionBase.subclasses
  end
  
  def setup_institution(institution_id)
    institution = institutions.find { |i| i.id == institution_id }
    
    if institution
      i = institution.new
      i.setup { |config| yield config }
    end
  end
end
