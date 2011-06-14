require 'date'
require 'mechanize'
require 'active_support/json'
require 'syrup/account'
require 'syrup/account_collection'
require 'syrup/transaction'

# require all institutions
require 'syrup/institutions/base'
Dir[File.dirname(__FILE__) + '/syrup/institutions/*.rb'].each {|file| require file }

module Syrup
  extend self
  
  def institutions
    Institutions::Base.subclasses
  end
  
  def setup_institution(institution_id, username, password, secret_questions)
    institution = institutions.find { |i| i.id == institution_id }
    
    if institution
      institution.new(username, password, secret_questions)
    end
  end
end
