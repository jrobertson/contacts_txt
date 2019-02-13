Gem::Specification.new do |s|
  s.name = 'contacts_txt'
  s.version = '0.2.10'
  s.summary = 'Reads a contacts.txt file'
  s.authors = ['James Robertson']
  s.files = Dir['lib/contacts_txt.rb']
  s.add_runtime_dependency('dynarex', '~> 1.8', '>=1.8.15')
  s.signing_key = '../privatekeys/contacts_txt.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/contacts_txt'
end
