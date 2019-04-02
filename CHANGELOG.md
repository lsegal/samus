# master

# 3.0.6 - April 02nd, 2019

[3.0.6]: https://github.com/lsegal/samus/compare/v3.0.5...v3.0.6

- Add `--skip-restore` to samus build to skip restoring Git repository. Useful
  with Docker build support in order to inspect output of a built release.
- Add `build/changelog-rotate` command for changelog rotation.
- Add `inspect` and `clean` Rake tasks for `DockerReleaseTask` to inspect and
  remove a previously built release respectively.

# 3.0.5 - April 1st, 2019

- Fix bug that breaks DockerReleaseTask if .gitconfig or .samus configs are
  not present on the system.

# 3.0.4 - April 1st, 2019

- Automatically build Dockerfile.samus as tempfile if it is not present in
  the repo when using `Samus::Rake::DockerReleaseTask`. This docker image
  copies all credentials in so it can be run directly without mounts.
- Add `mount_samus_config` option (defaults to `false`) to `DockerReleaseTask`
  options to allow Docker image to mount the Samus configuration directory
  from the host when publishing the image. To override the config directory,
  specify the `SAMUS_CONFIG_PATH` environment variable to the `publish` task.
- Add `extra_config` to `DockerReleaseTask` to allow extra files to be
  copied into the `/root` directory of the build image. The value should be
  a hash of src -> dest filenames to copy.

# 3.0.3 - April 1st, 2019

- Add `Samus::Rake::ReleaseTask` and `Samus::Rake::DockerReleaseTask` to
  generate helpful Rake tasks to generate releases. Example:

```ruby
require 'samus'

Samus::Rake::ReleaseTask.new do |t|
  t.git_pull_after_release = true # default is true
  t.zipfile = "customzip.tar.gz"  # default release-vX.Y.Z.tar.gz
  t.buildfile = "samus.json"      # default is samus.json
end
```

- Add `lsegal/samus:build` Dockerfile to simplify creation of build docker images.

# 3.0.2 - April 1st, 2019

- Add `chmod-files` command to fix file permissions on globs.

# 3.0.1 - March 30th, 2019

- Fix bug in `publish/github-release` command due to invalid tag handling.

# 3.0.0 - March 30th, 2019

- Add `build/ruby-bundle` command to run Bundler commands like install.
- Update `build/rake-task` to `bundle exec` when a Gemfile is present.
- Update `lsegal/samus` Docker image to contain Bundler 1.17.2.
- Update `build/changelog-parse` to support different formatting.
- Update `build/git-merge` to no longer pull from remote since credentials
  are not supported at build time.

# 2.0.3 - August 12th, 2018

- Add `--docker` support to build and publish which runs Samus inside a pre-built
  container with all default dependencies. You can provide
  `--docker-image image-name` to use a different image from the default
  `lsegal/samus` container.
- Fix `changelog-parse` command.

# 2.0.2 - August 11th, 2018

- Some more fixes for Windows compatibility when using `archive-git-full`.

# 2.0.0 - August 9th, 2018

- Add support for Windows. This caused a backwards incompatible change where
  environment variables are now UPPERCASED by default. In general this should
  have no effect if you rely only on built-in scripts.
- Report an error if credentials cannot be parsed.

# 1.6.0 - July 19, 2018

- Add support for credentials for git-push. Add a credentials file with
  an RSA key in the format `Key: ...RSA KEY HERE...`.
- Add experimental support for publishing via `lsegal/samus` Docker image. Use
  `samus publish --docker project-vX.Y.Z.tar.gz` to perform commands in a
  Docker image with the base support for all default publish commands. You must
  have Docker installed to use this flag.

# 1.4.3 - May 19, 2014

- Add `build/make-task` command to run a make task.

# 1.4.2 - October 26, 2014

- Add `build/changelog-parse` command to build ChangeLog from latest entries.

# 1.4.1 - October 24, 2014

- Remove date from title in `publish/github-release`

# 1.4.0 - October 24, 2014

- Add `publish/github-release` command.

# 1.3.0 - July 23, 2014

- Fix issue where repository would not reset when using `samus-build` command.
