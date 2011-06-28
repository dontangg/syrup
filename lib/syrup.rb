require 'date'
require 'mechanize'
require 'active_support/json'
require 'syrup/information_missing_error'
require 'syrup/account'
require 'syrup/transaction'

# require all institutions
require 'syrup/institutions/institution_base'
Dir[File.dirname(__FILE__) + '/syrup/institutions/*.rb'].each {|file| require file }

module Syrup
  extend self
  
  # Returns an array of institutions.
  #
  #   Syrup.institutions.each do |institution|
  #     puts "name: #{institution.name}, id: #{institution.id}"
  #   end
  def institutions
    Institutions::InstitutionBase.subclasses
  end
  
  # Returns a new institution object with the specified +institution_id+.
  # If you pass in a block, you can use it to setup the username, password, and secret_questions.
  #
  #   Syrup.setup_institution('zions_bank') do |config|
  #     config.username = "my_user"
  #     config.password = "my_password"
  #     config.secret_questions = {
  #       'How long is your beard?' => '6in'
  #     }
  #   end
  def setup_institution(institution_id)
    institution = institutions.find { |i| i.id == institution_id }
    
    if institution
      i = institution.new
      if block_given?
        i.setup { |config| yield config }
      else
        i
      end
    end
  end
end
