require_relative './action'

module Samus
  class BuildAction < Action
    def initialize(opts = {})
      super(opts)
      @pwd = nil
      @skip = false
    end

    attr_reader :publish

    def stage
      'build'
    end

    def command_options
      super.merge(pwd: @pwd)
    end

    attr_writer :pwd

    def run
      return if @skip
      super
    end

    def publish=(publish)
      @publish = publish.is_a?(Array) ? publish : [publish]
      @publish.each do |publish_action|
        publish_action['files'] ||= @files if @files
      end
    end

    attr_reader :skip
    def condition=(condition)
      @skip = !eval(condition)
    rescue StandardError => e
      puts "[E] Condition failed on #{@raw_options['action']}"
      raise e
    end
  end
end
