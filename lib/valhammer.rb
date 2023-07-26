require 'valhammer/version'
require 'valhammer/configuration'
require 'valhammer/validations'
require 'valhammer/railtie' if defined?(Rails::Railtie)

module Valhammer
  def self.config
    Configuration.instance
  end
end
