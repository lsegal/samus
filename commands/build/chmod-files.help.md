Corrects permissions for a set of globs. Pass arguments in files
with comma separating glob from permission bits. This command
auto-corrects directories to 775. Set dir_mask to override the
default mask value.

Example:

```json
"files": "bin/**/*,755 lib/**/*.rb,644"
```

Files:

- A list of globs and permissions separated by a comma, ex:
  `**/*.rb,644 **/*.sh,755`

Arguments:

- dir_mask: (optional) the directory umask to set. Defaults to 775.
