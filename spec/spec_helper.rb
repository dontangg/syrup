require 'rubygems'
require 'bundler/setup'
require 'syrup'

RSpec.configure do |config|
  include Syrup
end

module Syrup
  def spec_resource_path
    File.dirname(__FILE__) + '/resources/'
  end
end
