# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'coral_backup/version'

Gem::Specification.new do |spec|
  spec.name          = "coral_backup"
  spec.version       = CoralBackup::VERSION
  spec.authors       = ["OTSUKA Tatsuya"]
  spec.email         = ["tatzyr@gmail.com"]

  spec.summary       = %q{Coral Backup creates incremental backups of files that can be restored at a later date.}
  spec.homepage      = "https://github.com/tatzyr/coral_backup"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = "~> 2.0"
  spec.license       = "Zlib"

  spec.add_dependency "thor", "~> 0.19"
  spec.add_dependency "toml-rb", "~> 0.3"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
