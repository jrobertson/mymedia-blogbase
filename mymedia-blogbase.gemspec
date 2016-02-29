Gem::Specification.new do |s|
  s.name = 'mymedia-blogbase'
  s.version = '0.1.2'
  s.summary = 'Provides the basic features to publish page content'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_runtime_dependency('rdiscount', '~> 2.1', '>=2.1.7.1')
  s.add_runtime_dependency('mymedia', '~> 0.1', '>=0.1.0')
  s.add_runtime_dependency('martile', '~> 0.3', '>=0.3.5')
  s.signing_key = '../privatekeys/mymedia-blogbase.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/mymedia-blogbase'
end
