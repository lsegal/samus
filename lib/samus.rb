require_relative './samus/deployer'
require_relative './samus/builder'

module Samus
  module_function

  def config_paths; @@config_paths end

  @@config_paths = []

  def load_configuration_directory
    config_path = File.expand_path(ENV['SAMUS_CONFIG_PATH'] || '~/.samus')
    if File.exist?(config_path)
      Dir.foreach(config_path) do |dir|
        next if dir == '.' || dir == '..'
        dir = File.join(config_path, dir)
        config_paths.unshift(dir) if File.directory?(dir)
      end
    end
  end

  def load_commands
    config_paths.each do |path|
      path = File.join(path, 'commands')
      Samus::Command.command_paths.unshift(path) if File.directory?(path)
    end
  end

  def error(msg)
    puts "[E] #{msg}"
    exit(1)
  end
end

Samus.load_configuration_directory
Samus.load_commands
