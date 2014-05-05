$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rimpact/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rimpact"
  s.version     = Rimpact::VERSION
  s.authors     = ["Lei Wang"]
  s.email       = ["lei.wang@yale.edu"]
  s.homepage    = "http://library.medicine.yale.edu"
  s.summary     = "Rimpact parses bibliographic data in various formats and generates d3.js based visualization graphs."
  s.description = "Rimpact allows your Ruby on Rails application to parse bibliographic data in various formats and generate d3.js based visualization graphs."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_runtime_dependency "gnlookup"
  s.add_runtime_dependency "ref_parsers"
  s.add_runtime_dependency "bibtex-ruby"
end
