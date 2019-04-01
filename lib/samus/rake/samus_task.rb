require 'rake'
require 'rake/tasklib'

require_relative '../../samus'

module Samus
  module Rake
    module Helpers
      private

      def release_version
        return @version if defined?(@version)
        raise "Missing VERSION=X.Y.Z" unless ENV['VERSION']
        @version = ENV['VERSION'].sub(/^v/, '')
      end

      def release_image
        return @image if defined?(@image)
        @image = "samus/release/#{File.basename(Dir.pwd)}:v#{release_version}"
      end
    end

    class DockerReleaseTask < ::Rake::TaskLib
      include Helpers

      DEFAULT_DOCKERFILE = "Dockerfile.samus"

      attr_accessor :dockerfile

      attr_accessor :delete_image_after_publish

      attr_accessor :git_pull_after_publish

      def initialize(namespace = :samus)
        @namespace = namespace
        @dockerfile = DEFAULT_DOCKERFILE
        @delete_image_after_publish = true
        @git_pull_after_publish = true
        yield self if block_given?
        define
      end

      private
      
      def define
        namespace(@namespace) do
          desc '[VERSION=X.Y.Z] Builds a Samus release using Docker'
          task :build do
            img = release_image
            ver = release_version
            sh "docker build . -t #{img} -f #{dockerfile} --build-arg VERSION=#{ver}"
          end

          desc '[VERSION=X.Y.Z] Publishes a built release using Docker'
          task :publish do
            img = release_image
            mount = "#{Samus::CONFIG_PATH}:/root/.samus:ro"
            sh "docker run -v #{mount} --rm #{img}"
            sh "docker rmi -f #{img}" if delete_image_after_publish
            sh "git pull" if git_pull_after_publish
          end
        end
      end
    end

    class ReleaseTask < ::Rake::TaskLib
      include Helpers

      attr_accessor :git_pull_after_publish
      attr_accessor :buildfile
      attr_writer :zipfile

      def initialize(namespace = :samus)
        @namespace = namespace
        @buildfile = ""
        @zipfile = nil
        @git_pull_after_publish = true
        yield self if block_given?
        define
      end

      private

      def zipfile
        @zipfile || "release-v#{release_version}.tar.gz"
      end
      
      def define
        namespace(@namespace) do
          desc '[VERSION=X.Y.Z] Builds a Samus release'
          task :build do
            sh "samus build -o #{zipfile} #{release_version} #{buildfile}"
          end

          desc '[VERSION=X.Y.Z] Publishes a built release'
          task :publish do
            sh "samus publish #{zipfile}"
            sh "git pull" if git_pull_after_publish
          end
        end
      end
    end
  end
end
