require 'singleton'

module Valhammer
  class Configuration
    include Singleton

    def initialize
      @verbose = false
    end

    attr_accessor :verbose
    alias verbose? verbose
  end
end
