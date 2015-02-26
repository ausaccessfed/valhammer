require 'active_record'
require 'logger'

FileUtils.mkdir_p('log')

ActiveRecord::Base.logger = Logger.new('log/debug.log')
ActiveRecord::Base.extend Valhammer::Validations

ActiveRecord::Base.establish_connection(adapter: 'sqlite3',
                                        database: 'spec/db/test.sqlite3')

require_relative 'schema.rb'
