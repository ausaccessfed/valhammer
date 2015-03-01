require File.expand_path('../boot', __FILE__)

require 'active_record/railtie'
require 'valhammer'

module Dummy
  class Application < Rails::Application
    config.cache_classes = true
    config.eager_load = false

    config.consider_all_requests_local = true
    config.action_dispatch.show_exceptions = false
  end
end
