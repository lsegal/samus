require 'json'
require 'tmpdir'

require_relative './build_action'

module Samus
  class Builder
    RESTORE_FILE = ".git/samus-restore"

    attr_reader :build_manifest

    def initialize(build_manifest_file)
      @stage = 'build'
      @build_manifest_file = build_manifest_file
      @build_manifest = JSON.parse(File.read(build_manifest_file).gsub('$version', $VERSION))
      @manifest = {}
    end

    def build(dry_run = false, zip_release = true, outfile = nil)
      orig_pwd = Dir.pwd
      manifest = {'version' => $VERSION, 'actions' => []}
      build_branch = "samus-release/v#{$VERSION}"
      orig_branch = `git symbolic-ref -q --short HEAD`.chomp

      if `git diff --shortstat 2> /dev/null | tail -n1` != ""
        Samus.error "Repository is dirty, it is too dangerous to continue."
      end

      system "git checkout -qb #{build_branch} 2>/dev/null"
      remove_restore_file

      Dir.mktmpdir do |build_dir|
        actions.map do |action|
          BuildAction.new(:dry_run => dry_run, :arguments => {
            "_restore_file" => RESTORE_FILE,
            "_build_dir" => build_dir,
            "_build_branch" => build_branch,
            "version" => $VERSION
          }).load(action)
        end.each do |action|
          next if action.skip
          action.run
          manifest['actions'] += action.publish if action.publish
        end

        Dir.chdir(build_dir) do
          generate_manifest(manifest)
          generate_release(orig_pwd, zip_release)
        end unless dry_run
      end

    ensure
      restore_git_repo
      system "git checkout -q #{orig_branch} 2>/dev/null"
      system "git branch -qD #{build_branch} 2>/dev/null"
    end

    private

    def generate_manifest(manifest)
      File.open('manifest.json', 'w') do |f|
        f.puts JSON.pretty_generate(manifest, indent: '  ')
      end
    end

    def generate_release(orig_pwd, zip_release = true, outfile = nil)
      file = outfile || build_manifest['output'] || "release-v#{$VERSION}"
      file = File.join(orig_pwd, file) unless file[0] == '/'
      if zip_release
        file += '.tar.gz'
        system "tar cfz #{file} *"
      else
        system "mkdir -p #{file} && cp -r * #{file}"
      end
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
        when "tag"
          puts "[D] Removing tag #{branch}" if $DEBUG
          system "git tag -d #{branch} >/dev/null"
        when "branch"
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
  end
end
