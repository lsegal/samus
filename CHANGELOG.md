# 1.6.4 - August 9th, 2018

- Add support for Windows portability
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
