require_relative './command'
require_relative './credentials'

module Samus
  class Action
    def initialize(opts = {})
      @raw_options = opts
      @dry_run = opts[:dry_run]
      @allow_fail = false
      @command = nil
      @creds = nil
      @arguments = opts[:arguments] || {}
    end

    def stage; raise NotImplementedError, 'action must define stage' end

    def load(opts = {})
      opts.each do |key, value|
        meth = "#{key}="
        if respond_to?(meth)
          send(meth, value)
        else
          Samus.error("Unknown action property: #{key}")
        end
      end
      self
    end

    def run
      @command.run(command_options) if @command
    end

    def command_options
      {
        :arguments => @creds ? @arguments.merge(@creds.load) : @arguments,
        :files => @files,
        :dry_run => @dry_run,
        :allow_fail => @allow_fail
      }
    end

    def action=(name)
      @command = Command.new(stage, name)
    end

    def credentials=(key)
      @creds = Credentials.new(key)
    end

    def allowFail=(value)
      @allow_fail = value
    end

    attr_writer :files

    def arguments=(args)
      args.each {|k, v| @arguments[k] = v }
    end
  end
end
