module Valhammer
  class Railtie < ::Rails::Railtie
    initializer 'valhammer.install' do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.extend Valhammer::Validations
      end
    end
  end
end
