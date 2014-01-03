module Samus
  class Stage
    class << self
      def command_paths; @@command_paths end
    end

    @@command_paths = [File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'commands'))]

    def initialize(*)
      @creds = {}
      @stage_type = nil
    end

    private

    def run_command(command, env, args, dry_run = false, allow_fail = false)
      display_command(command, env, args)
      if base_path = find_command(command)
        if !dry_run
          system(env, File.join(base_path, @stage_type, command) + " " + (args ? args.join(" ") : ""))
          if $?.to_i != 0
            puts "[E] Last command failed with #{$?}#{allow_fail ? ' but allowFail=true' : ', exiting'}."
            exit($?.to_i) unless allow_fail
          end
        end
      else
        puts "[E] Could not find command: #{command} " +
             "(SAMUS_COMMAND_PATH=#{self.class.command_paths.join(':')})"
        exit(1)
      end
    end

    def find_command(cmd)
      self.class.command_paths.find {|path| File.exist?(File.join(path, @stage_type, cmd)) }
    end

    def display_command(command, env, args)
      e = env.map {|k,v| k =~ /^(AWS|__)/ ? nil : "#{k}=#{v.inspect}" }.compact.join(" ")
      e = e + " " if e.size > 0
      puts("[C] " + e + command + (args ? " " + args.join(" ") : ""))
    end

    def add_credentials(creds, env)
    end
  end
end
