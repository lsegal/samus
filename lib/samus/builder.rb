require 'json'
require 'tmpdir'

require_relative './build_action'

module Samus
  class Builder
    RESTORE_FILE = '.git/samus-restore'.freeze

    class << self
      attr_accessor :build_version
    end

    attr_reader :build_manifest

    def initialize(build_manifest_file)
      fdata = File.read(build_manifest_file).gsub('$version', version)
      @stage = 'build'
      @build_manifest_file = build_manifest_file
      @build_manifest = JSON.parse(fdata)
      @manifest = {}
    end

    def build(dry_run = false, zip_release = true, outfile = nil)
      orig_pwd = Dir.pwd
      manifest = { 'version' => version, 'actions' => [] }
      build_branch = "samus-release/v#{version}"
      orig_branch = `git symbolic-ref -q --short HEAD`.chomp

      if `git diff --shortstat 2> #{devnull} | tail -n1` != ''
        Samus.error 'Repository is dirty, it is too dangerous to continue.'
      end

      system "git checkout -qb #{build_branch} 2>#{devnull}"
      remove_restore_file

      Dir.mktmpdir do |build_dir|
        actions.map do |action|
          BuildAction.new(dry_run: dry_run, arguments: {
                            '_restore_file' => RESTORE_FILE,
                            '_build_dir' => build_dir,
                            '_build_branch' => build_branch,
                            '_devnull' => devnull,
                            'version' => version
                          }).load(action)
        end.each do |action|
          next if action.skip
          action.run
          manifest['actions'] += action.publish if action.publish
        end

        unless dry_run
          Dir.chdir(build_dir) do
            generate_manifest(manifest)
            generate_release(orig_pwd, zip_release, outfile)
          end
        end
      end
    ensure
      restore_git_repo
      system "git checkout -q #{orig_branch} 2>#{devnull}"
      system "git branch -qD #{build_branch} 2>#{devnull}"
    end

    private

    def generate_manifest(manifest)
      File.open('manifest.json', 'w') do |f|
        f.puts JSON.pretty_generate(manifest, indent: '  ')
      end
    end

    def generate_release(orig_pwd, zip_release = true, outfile = nil)
      file = outfile || build_manifest['output'] || "release-v#{version}"
      file = File.join(orig_pwd, file) unless file[0] == '/'
      file_is_zipped = file =~ /\.(tar\.gz|tgz)$/
      if zip_release || file_is_zipped
        file += '.tar.gz' unless file_is_zipped
        system "tar cfz #{file} *"
      else
        system "mkdir -p #{file} && cp -R * #{file}"
      end
      Samus.error "Failed to build release package" if $?.to_i != 0
      puts "[I] Built release package: #{File.basename(file)}"
    end

    def actions
      build_manifest['actions']
    end

    def restore_git_repo
      return unless File.file?(RESTORE_FILE)

      File.readlines(RESTORE_FILE).each do |line|
        type, branch, commit = *line.split(/\s+/)
        case type
        when 'tag'
          puts "[D] Removing tag #{branch}" if $DEBUG
          system "git tag -d #{branch} >#{devnull}"
        when 'branch'
          puts "[D] Restoring #{branch} to #{commit}" if $DEBUG
          system "git checkout -q #{branch}"
          system "git reset -q --hard #{commit}"
        end
      end
    ensure
      remove_restore_file
    end

    def remove_restore_file
      File.unlink(RESTORE_FILE) if File.file?(RESTORE_FILE)
    end

    def version
      self.class.build_version
    end

    def devnull
      windows? ? 'NUL' : '/dev/null'
    end

    def windows?
      ::RbConfig::CONFIG['host_os'] =~ /mingw|win32|cygwin/ ? true : false
    end
  end
end
