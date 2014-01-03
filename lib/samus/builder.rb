require_relative './stage'
require 'json'
require 'tmpdir'

module Samus
  class Builder < Stage
    RESTORE_FILE = ".git/samus-restore"

    attr_reader :build_manifest

    def initialize(build_manifest_file)
      super
      @stage_type = 'build'
      @build_manifest_file = build_manifest_file
      @build_manifest = JSON.parse(File.read(build_manifest_file).gsub('$version', $VERSION))
      @manifest = {}
    end

    def build(dry_run = false)
      orig_pwd = Dir.pwd
      manifest = {'version' => $VERSION, 'actions' => []}
      build_branch = "samus-release/v#{$VERSION}"
      orig_branch = `git symbolic-ref -q --short HEAD`.chomp

      system "git checkout -b #{build_branch} 2>/dev/null"
      remove_restore_file

      Dir.mktmpdir do |build_dir|
        actions.each do |action|
          begin
            next if action['condition'] && !eval(action['condition'])
          rescue => e
            puts "[E] Condition failed on #{action['action']}"
            raise e
          end

          env = {
            "__restore_file" => RESTORE_FILE,
            "__build_dir" => build_dir,
            "__build_branch" => build_branch,
            "_version" => $VERSION
          }
          action['arguments'].each do |key, value|
            env["_#{key}"] = value.gsub('$version', $VERSION)
          end if action['arguments']

          Dir.chdir(action['pwd'] || orig_pwd) do
            add_credentials(action['creds'], env)
            run_command(action['action'], env, action['files'],
              dry_run, action['allowFail'] || false)
          end if action['action']

          if action['deploy']
            action['deploy'] = [action['deploy']] unless action['deploy'].is_a?(Array)
            action['deploy'].each do |deploy_action|
              deploy_action['files'] = action['files'] if action['files']
            end
            manifest['actions'] += action['deploy']
          end
        end

        Dir.chdir(build_dir) do
          generate_manifest(manifest)
          generate_zipfile(orig_pwd)
        end unless dry_run
      end

    ensure
      restore_git_repo
      system "git checkout #{orig_branch} 2>&1 >/dev/null"
      system "git branch -D #{build_branch} 2>&1 >/dev/null"
    end

    private

    def generate_manifest(manifest)
      File.open('manifest.json', 'w') do |f|
        f.puts JSON.pretty_generate(manifest, indent: '  ')
      end
    end

    def generate_zipfile(orig_pwd)
      file = build_manifest['output'] || 'release.tar.gz'
      file = File.join(orig_pwd, file)
      system "tar cfz #{file} *"
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
          puts "[D] Removing tag #{branch}"
          system "git tag -d #{branch} 2>&1 >/dev/null"
        when "branch"
          puts "[D] Restoring #{branch} to #{commit}"
          system "git checkout #{branch} 2>&1 >/dev/null"
          system "git reset --hard #{commit} 2>&1 >/dev/null"
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
