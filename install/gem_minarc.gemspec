Gem::Specification.new do |s|
  s.name        = 'minarc'
  s.version     = '1.0.0'
  s.licenses    = ['MIT']
  s.summary     = "DEC/MINARC component"
  s.description = "Minimum Archive"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
  s.files       = Dir['../code/arc/*.rb'] + Dir['../code/cuc/*.rb'] + Dir['../code/ctc/*.rb']
  s.homepage    = 'http://www.deimos-space.com'
  s.metadata    = { "source_code_uri" => "https://github.com/example/example" }
end
