Rotates the latest ChangeLog entries into an arbitrary formatted title heading.
The heading is formatted via `title_format` and can include the version
and release date.

Files:

- The path to the ChangeLog file.

Arguments:

- heading: (optional) defaults to primary branch name, should match the first development
  heading used for in-flux changelog entries before rotation.
- title_format: (optional) a `Time.strftime` date formatted string that can
  also include `$version` to represent the title of the rotated changelog entry.
  Example: `$version - %B %-d, %Y`. It is recommended to put the version at the
  front of the title to improve the reliability of generating a compare URL.
- tz: (optional) set the timezone if not available on the build system. Defaults
  to system timezone.
