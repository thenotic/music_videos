# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "music_videos"
  spec.version       = '0.0.12'
  spec.authors       = ["thenotic"]
  spec.email         = ["liban.aliyusuf@gmail.com"]
  spec.summary       = "Finds Artist Music Videos"
  spec.description   = "Yes"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "typhoeus"
  spec.add_dependency "rmagick"
  spec.add_development_dependency "rspec", "~> 3.2"




end
