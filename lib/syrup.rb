require 'date'
require 'mechanize'
require 'active_support/json'
require_relative 'syrup/account'
require_relative 'syrup/transaction'

# require all institutions
require_relative 'syrup/institutions/base'
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
