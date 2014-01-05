require_relative './stage'
require 'json'

module Samus
  class Deployer < Stage
    def initialize(dir)
      super
      @dir = dir
      @stage = 'deploy'
    end

    def deploy(dry_run = false)
      Dir.chdir(@dir) do
        actions.each do |action|
          env = {'_version' => manifest['version']}
          action['arguments'].each do |key, value|
            env["_#{key}"] = value
          end if action['arguments']

          add_credentials(action['creds'], env) unless dry_run
          run_command(action['action'], env, action['files'],
            dry_run, action['allowFail'] || false)
        end
      end
    end

    private

    def actions
      manifest['actions']
    end

    def manifest
      @manifest ||= JSON.parse(File.read(manifest_file))
    end

    def manifest_file
      @manifest_file ||= File.join(@dir, 'manifest.json')
    end
  end
end
