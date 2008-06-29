Gem::Specification.new do |s|
  s.name = "lonely_planet"
  s.version = "0.1.0"
  s.date = "2008-06-25"
  s.summary = "A Ruby object-oriented interface to the Lonely Planet REST API."
  s.email = "andy@mibly.com"
  s.homepage = "http://mibly.com"
  s.description = "A Ruby object-oriented interface to the  Lonely Planet REST API."
  s.has_rdoc = true
  s.authors = ["Andy Shearer"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "lonelyplanet.gemspec", "./lib/lonely_planet.rb", "./test/test_lonely_planet.rb"]
  s.test_files = ["test/test_lonely_planet.rb"]
  s.rdoc_options = ["--main", "README.txt"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.add_dependency("xml-simple", ["> 1.0.0"])
end