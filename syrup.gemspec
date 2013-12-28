# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "syrup/version"

Gem::Specification.new do |s|
  s.name        = "syrup"
  s.version     = Syrup::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Don Wilson"]
  s.email       = ["dontangg@gmail.com"]
  s.homepage    = "http://github.com/dontangg/syrup"
  s.summary     = %q{Simple account balance and transactions extractor.}
  s.description = %q{Simple account balance and transactions extractor by scraping bank websites.}
  
  s.add_dependency "mechanize", ">= 1.0.0"
  s.add_dependency "multi_json", ">= 1.0.3"
  
  s.add_development_dependency "rspec", ">= 2.6.0"
  #s.add_development_dependency "debugger"
  s.add_development_dependency "rake"

  s.rubyforge_project = s.name

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
