Bundler.setup
require 'simplecov'

ENV['RAILS_ENV'] = 'test'
FileUtils.rm_f 'spec/db/test.sqlite3'

require_relative 'dummy/config/environment.rb'
require_relative 'db/schema.rb'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.disable_monkey_patching!

  config.order = :random
  Kernel.srand config.seed
end
