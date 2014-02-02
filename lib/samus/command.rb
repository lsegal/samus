module Samus
  class Command
    class << self
      def command_paths; @@command_paths end

      def list_commands(stage = nil)
        display_commands(collect_commands(stage))
      end

      private

      def display_commands(stages)
        puts "Commands:"
        puts ""
        stages.each do |type, commands|
          puts "#{type}:"
          puts ""
          commands.sort.each do |command|
            puts("  * %-20s%s" % [command.name, command.help_text.split(/\r?\n/)[0]])
          end
          puts ""
        end
      end

      def collect_commands(stage)
        stages = {}
        command_paths.each do |path|
          Dir.glob(File.join(path, '*', '*')).each do |dir|
            type, name = *dir.split(File::SEPARATOR)[-2,2]
            next if name =~ /\.md$/
            next if stage && stage != type
            (stages[type] ||= []).push(new(type, name))
          end
        end
        stages
      end
    end

    @@command_paths = [File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'commands'))]

    attr_reader :stage, :name

    def initialize(stage, name)
      @name = name
      @stage = stage
      load_full_path
    end

    def show_help
      puts "#{stage.capitalize} Command: #{name}"
      puts ""
      puts help_text
    end

    def help_text
      @help_text ||= File.exist?(help_path) ? File.read(help_path) : ""
    end

    def log_command(env = {}, arguments = [])
      e = env.map {|k,v| k =~ /^(AWS|__)/ ? nil : "#{k}=#{v.inspect}" }.compact.join(" ")
      e = e + " " if e.size > 0
      puts("[C] " + e + name + (arguments ? " " + arguments.join(" ") : ""))
    end

    def run(opts = {})
      env = (opts[:arguments] || {}).inject({}) {|h, (k, v)| h["_#{k}"] = v; h }
      arguments = opts[:files] || []
      dry_run = opts[:dry_run] || false
      allow_fail = opts[:allow_fail] || false
      pwd = opts[:pwd]
      old_pwd = Dir.pwd

      log_command(env, arguments)
      if !dry_run
        exec_in_dir(pwd) do
          system(env, @full_path + " " + (arguments ? arguments.join(" ") : ""))
        end
        report_error($?, allow_fail)
      end
    end

    def <=>(other)
      name <=> other.name
    end

    private

    def report_error(exit_code, allow_fail)
      return if exit_code.to_i == 0
      puts "[E] Last command failed with #{exit_code}#{allow_fail ? ' but allowFail=true' : ', exiting'}."
      exit(exit_code.to_i) unless allow_fail
    end

    def exec_in_dir(dir, &block)
      dir ? Dir.chdir(dir, &block) : yield
    end

    def load_full_path
      if path = self.class.command_paths.find {|path| File.exist?(File.join(path, stage, name)) }
        @full_path = File.join(path, stage, name)
      else
        Samus.error "Could not find command: #{name} " +
          "(cmd_paths=#{self.class.command_paths.join(':')})"
      end
    end

    def help_path
      @help_path ||= @full_path + '.help.md'
    end
  end
end
