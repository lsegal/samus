require File.expand_path('../lib/samus/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = 'samus'
  s.summary       = 'Samus helps you release Open Source Software.'
  s.version       = Samus::VERSION
  s.author        = 'Loren Segal'
  s.email         = 'lsegal@soen.ca'
  s.homepage      = 'http://github.com/lsegal/samus'
  s.files         = `git ls-files`.split(/\s+/)
  s.executables   = ['samus']
  s.license       = 'BSD'
end
