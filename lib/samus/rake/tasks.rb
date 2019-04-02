require 'rake'
require 'rake/tasklib'
require 'tempfile'
require 'fileutils'

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

      PREP_DIR = '.samusprep'
      DEFAULT_DOCKERFILE = "Dockerfile.samus"

      attr_accessor :dockerfile

      attr_accessor :delete_image_after_publish

      attr_accessor :git_pull_before_build

      attr_accessor :git_pull_after_publish

      attr_accessor :mount_samus_config

      attr_accessor :extra_config

      def initialize(namespace = :samus)
        @namespace = namespace
        @dockerfile = DEFAULT_DOCKERFILE
        @delete_image_after_publish = true
        @git_pull_before_build = true
        @git_pull_after_publish = true
        @mount_samus_config = false
        @extra_config = {}

        yield self if block_given?

        build_config_files
        define
      end

      private

      def build_config_files
        @config_files = {
          Samus::CONFIG_PATH => '.samus',
          File.expand_path('~/.gitconfig') => '.gitconfig'
        }.merge(extra_config)
        @config_files.select! {|src, _dst| File.exist?(src) }
      end

      def copy_prep
        FileUtils.rm_rf(PREP_DIR)
        FileUtils.mkdir_p(PREP_DIR)
        @config_files.each do |src, dst|
          FileUtils.cp_r(src, File.join(PREP_DIR, dst))
        end
      end

      def build_or_get_dockerfile
        return dockerfile if File.exist?(dockerfile)
        fname = File.join(PREP_DIR, 'Dockerfile')
        config_copies = @config_files.values.map {|f| "COPY ./#{PREP_DIR}/#{f} /root/#{f}" }
        File.open(fname, 'w') do |f|
          f.puts([
            "FROM lsegal/samus:build",
            "ARG VERSION",
            "ENV VERSION=${VERSION}",
            "COPY . /build",
            config_copies.join("\n"),
            "RUN rm -rf /build/.samusprep",
            "RUN samus build --skip-restore ${VERSION}"
          ].join("\n"))
        end
        fname
      end

      def define
        namespace(@namespace) do
          desc '[VERSION=X.Y.Z] Builds a Samus release using Docker'
          task :build do
            img = release_image
            ver = release_version
            sh "git pull" if git_pull_before_build

            begin
              copy_prep
              sh "docker build . --rm -t #{img} -f #{build_or_get_dockerfile} --build-arg VERSION=#{ver}"
            ensure
              FileUtils.rm_rf(PREP_DIR)
            end
          end

          desc '[VERSION=X.Y.Z] Publishes a built release using Docker'
          task :publish do
            img = release_image
            mount = mount_samus_config ? "-v #{Samus::CONFIG_PATH}:/root/.samus:ro" : ''
            sh "docker run #{mount} --rm #{release_image}"
            Rake::Task["#{@namespace}:clean"].execute if delete_image_after_publish
            sh "git pull" if git_pull_after_publish
          end

          desc '[VERSION=X.Y.Z] Inspects a built release using Docker shell'
          task :inspect do
            sh "docker run -it --entrypoint sh #{release_image}"
          end

          desc '[VERSION=X.Y.Z] Removes a built release using Docker'
          task :clean do
            sh "docker rmi -f #{release_image}"
          end
        end
      end
    end

    class ReleaseTask < ::Rake::TaskLib
      include Helpers

      attr_accessor :git_pull_before_build
      attr_accessor :git_pull_after_publish
      attr_accessor :buildfile
      attr_writer :zipfile

      def initialize(namespace = :samus)
        @namespace = namespace
        @buildfile = ""
        @zipfile = nil
        @git_pull_before_build = true
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
            sh "git pull" if git_pull_before_build
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
