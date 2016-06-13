# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'valhammer/version'

Gem::Specification.new do |spec|
  spec.name          = 'valhammer'
  spec.version       = Valhammer::VERSION
  spec.authors       = ['Shaun Mangelsdorf']
  spec.email         = ['s.mangelsdorf@gmail.com']
  spec.summary       = 'Automatically validate ActiveRecord models based on ' \
                       'the database schema.'
  spec.homepage      = 'https://github.com/ausaccessfed/valhammer'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '> 4.1'

  spec.add_development_dependency 'rails', '> 4.1'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-bundler'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'codeclimate-test-reporter'
  spec.add_development_dependency 'sqlite3'
end
