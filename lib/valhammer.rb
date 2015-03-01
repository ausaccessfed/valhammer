require 'valhammer/version'

module Valhammer
end

require 'valhammer/validations'
require 'valhammer/railtie' if defined?(Rails::Railtie)
