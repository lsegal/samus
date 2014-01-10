require_relative './action'

module Samus
  class BuildAction < Action
    def initialize(opts = {})
      super(opts)
      @pwd = nil
      @skip = false
    end

    attr_reader :deploy

    def stage; 'build' end

    def command_options
      super.merge(:pwd => @pwd)
    end

    def pwd=(pwd)
      @pwd = pwd
    end

    def run
      return if @skip
      super
    end

    def deploy=(deploy)
      @deploy = Array === deploy ? deploy : [deploy]
      @deploy.each do |deploy_action|
        deploy_action['files'] ||= @files if @files
      end
      @deploy
    end

    def condition=(condition)
      begin
        @skip = !eval(condition)
      rescue => e
        puts "[E] Condition failed on #{@raw_options['action']}"
        raise e
      end
    end
  end
end
