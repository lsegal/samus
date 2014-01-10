require_relative './samus/deployer'
require_relative './samus/builder'

module Samus
  CONFIG_PATH = File.expand_path(ENV['SAMUS_CONFIG_PATH'] || '~/.samus')

  module_function

  def config_paths; @@config_paths end

  @@config_paths = []

  def load_configuration_directory
    if File.exist?(CONFIG_PATH)
      Dir.foreach(CONFIG_PATH) do |dir|
        next if dir == '.' || dir == '..'
        dir = File.join(CONFIG_PATH, dir)
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
