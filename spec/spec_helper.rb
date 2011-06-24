require 'rubygems'
require 'bundler/setup'
require 'syrup'

RSpec.configure do |config|
  include Syrup
  
  config.filter_run_excluding :bank_integration => true
end

module Syrup
  def spec_resource_path
    File.dirname(__FILE__) + '/resources/'
  end
end
