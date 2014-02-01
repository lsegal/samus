require 'json'

require_relative './publish_action'

module Samus
  class Publisher
    def initialize(dir)
      @dir = dir
      @stage = 'publish'
    end

    def publish(dry_run = false)
      Dir.chdir(@dir) do
        actions.map do |action|
          PublishAction.new(:dry_run => dry_run, :arguments => {
            'version' => manifest['version']
          }).load(action)
        end.each do |action|
          action.run
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
