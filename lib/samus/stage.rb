require_relative './command'

module Samus
  class Stage
    class << self
      def command_paths; @@command_paths end
    end

    @@command_paths = [File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'commands'))]

    def initialize(*)
      @creds = {}
      @stage = nil
    end

    def run_command(name, env, args, dry_run = false, allow_fail = false)
      Command.new(@stage, name).run(env, args, dry_run, allow_fail)
    end

    def add_credentials(creds, env)
    end
  end
end
