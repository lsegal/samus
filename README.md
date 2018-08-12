# Samus <a href="http://badge.fury.io/rb/samus"><img src="https://badge.fury.io/rb/samus@2x.png" alt="Gem Version" height="18"></a> [![Code Climate](https://codeclimate.com/github/lsegal/samus.png)](https://codeclimate.com/github/lsegal/samus)

Samus helps you automate the release of Open Source Software. Samus works
through a manifest file to describe discrete steps that you typically perform
when packaging and publishing code.

Samus comes with a set of built-in commands that let you prepare your
repository, push your changes, package your library, and upload it to various
locations / package managers. Samus is also open-source, so you can contribute
new commands if you think they are useful to others. Finally, Samus allows you
to install and share custom commands and credentials for building and publishing
your code. That's right, Samus has a mechanism to share publishing credentials
in a fairly secure way, so you can reliably publish releases from almost any
machine.

## Installing

Samus is a RubyGem and requires Ruby 1.9.x+. Installing is as easy as typing:

```sh
$ gem install samus
```

If you would rather use Samus via Docker, see the Docker section in Usage below.

## Usage

Samus is driven by a manifest file that describes the steps to perform when
building or publishing a release. You can just use Samus to publish, or you
can use it for both, it's your choice.

### Publishing

If you can handle building all of your assets on your own, you can use Samus
just to publish your code. Create a manifest file called `manifest.json` (it
must be named this way) and put it in a directory with all of your assets. The
manifest file is just a list of discrete actions like so (minus comments):

```js
{
  "actions": [
    {
      "files": "git.tgz",       // this is an archive of your git repository
      "action": "git-push",
      "arguments": {
        "remotes": "origin",
        "refs": "master v1.5.0" // the v1.5.0 is a tag for your release
      }
    },
    {
      "action": "gem-push",
      "files": ["my-built-gemfile.gem"],
      "credentials": "my-credentials-key"
    }
  ]
}
```

Note: The credentials section defines a flat file or executable Samus looks
at to get your key for authentication. See the "Custom Commands & Credentials"
section below for how to point to this file.

Now just run `samus publish .`, and Samus will run these commands in order,
pushing your Git repository and your RubyGem to the world.

### Building

In most cases you will want some help staging a release; Samus can help with
that too. Just in the same way you created a manifest for publishing, you
create a manifest file for building your release. The only difference is now
you include build-time actions, in addition to your publish actions.

Here is an example that updates your version.rb file, commits and tags the
release, and zips up your repository and RubyGem for publishing. Call
it "samus.json" for easier integration:

```js
// samus.json:
{
  "actions": [
    {
      "action": "fs-sedfiles",
      "files": ["lib/my-gem/version.rb"],
      "arguments": {
        "search": "VERSION = ['\"](.+?)['\"]",
        "replace": "VERSION = '$version'"
      }
    },
    {
      "action": "git-commit",
      "files": ["lib/my-gem/version.rb"]
    },
    {
      "action": "git-merge", // merge new commit into master branch
      "arguments": {
        "branch": "master"
      }
    },
    {
      "action": "archive-git-full",
      "files": ["git.tgz"],
      "publish": [{
        "action": "git-push",
        "arguments": {
          "remotes": "origin",
          "refs": "master v$version"
        }
      }]
    },
    {
      "action": "gem-build",
      "files": ["my-gem.gemspec"],
      "publish": [
        {
          "action": "gem-push",
          "files": ["my-gem-$version.gem"],
          "credentials": "my-credentials-key"
        }
      ]
    }
  ]
}
```

It looks a little longer, but it contains all of the steps to automate when
bumping the VERSION constant, tagging a version, merging into the master
branch, and building the gem. To build a release with this manifest, simply
type:

```sh
$ samus build 1.5.0
```

Samus will look for `samus.json` and build a release for version 1.5.0 of your
code. It will produce an archive called `release-v1.5.0.tar.gz` that you
can then publish with:

```sh
$ samus publish release-v1.5.0.tar.gz
```

You may have noticed some funny looking "$version" strings in the above
manifest. Those strings will be replaced with the version provided in the
build command, so all the correct tagging and building will be handled for you.

You will also notice that the publish commands are part of this manifest.
In build mode, Samus handles building of the manifest.json document, grabbing
any of the "publish" sections of an action and throwing them in the final
manifest.json. As illustrated above, not all actions require a publish section.
If you want to inspect the manifest file that Samus created, you can build
your release as a directory instead of a zip with `--no-zip`.

Note: If you didn't name your manifest samus.json you can simply enter the
filename in the build command as `samus build VERSION manifest.json`.

### Docker Support

If you would prefer to run Samus on a pre-built image with prepared
dependencies, you can use the
[lsegal/samus](https://hub.docker.com/r/lsegal/samus/) Docker image as follows:

```sh
docker run --rm -v $HOME:/root -w /root/${PWD#$HOME} -it lsegal/samus \
  samus build <VERSION>
```

Remember to replace `<VERSION>` with your version string (i.e. `1.0.0`). Then
to publish, use:

```sh
docker run --rm -v $HOME:/root -w /root/${PWD#$HOME} -it lsegal/samus \
  samus publish release-v<VERSION>.tar.gz
```

#### Docker Isolation Notes

Note that these instructions are _not_ meant to run an isolated release
environment, but instead as a convenience to provide all of the non-Ruby
dependencies that Samus might need. If you wish to build and deploy from an
isolated environment, you would have to build a Dockerfile `FROM lsegal/samus`
and ensure that all necessary credentials and configuration is copied in. This
is an exercise left up to the user, since it can be complex and depends on the
amount of configuration needed for building (Git configuration, SSH keys, etc).

Also note that this syntax is currently only supported for POSIX style systems
and does not yet support Windows.

## Built-in Commands

Samus comes with a number of built-in commands optimized for dealing with
the Git workflow. You can use `samus show-cmd` to list all available commands,
both for building and publishing a release. Each command has documentation
for which files and arguments it accepts.

```sh
$ samus show-cmd
... a list of commands ...
```

To view a specific command, make sure to include the stage (`build` or
`publish`):

```sh
$ samus show-cmd publish git-push
Publish Command: git-push

Pushes Git repository refs to a set of remotes.

Files:
  * The repository archive filename.

Arguments:
  * refs:    a space delimited set of commits, branches, or tags to push.
  * remotes: a space delimited set of remotes to push refs to.
```

## Custom Commands & Credentials

Sometimes you will need to create custom commands that do specific things
for your project. If they are generic, you should submit them to this project,
but if not, you can install custom commands that only you have access to.
This goes for credentials too, which you can install privately on your
machine.

Samus works best when custom packages are Git-backed (preferably private)
repositories. In this case, you can simply type `samus install REPO` to
download the repository to your machine:

```sh
$ samus install git@github.com:my_org/samus_config
```

Of course, Samus doesn't need these custom packages to be Git-backed. All
the above command does is clone a repository into the ~/.samus directory.
The above command creates:

```
.samus/
  `- samus_config/
     `- commands/
        `- build/
           `- my-command
     `- credentials/
        `- my-credentials-key
```

### Commands

Commands in Samus are just shell scripts which execute from the workspace
or release directory (unless overridden by the build manifest). Samus passes
all argument values (the keys from the "arguments" section of the manifest) in
as environment variables with a prefixed underscore. For example, the
`rake-task` command is just:

```sh
#!/bin/sh

rake $_TASK
```

The `$_TASK` variable is the "task" argument from the manifest.

Note that commands must be executable (`chmod +x`) and have proper shebang
lines or they will not function.

#### Stages

Commands either live in the build/ or publish/ sub-directories under the
commands directory depending on whether they are for `samus build` or
`samus publish`. These are considered the respective "stages".

#### Special Variables

In addition to exposing arguments as underscored environment variables,
Samus also exposes a few special variables with double underscore prefixes:

- `__build_dir` - this variable refers to the temporary directory that the
  release package is being built inside of. The files inside of this directory,
  and _only_ the files inside of this directory, will be built into the release
  archive. If you write a build-time command that produces an output file which
  is part of the release, you should make sure to move it into this directory.
- `__restore_file` - the restore file is a newline delimited file containing
  branches and their original ref. All branches listed in this file will be
  restored to the respective ref at the end of `samus build` regardless of
  success status. If you make destructive modifications to existing branches
  in the workspace repository, you should add the original ref for the branch
  to this file.
- `__creds_*` - provides key, secret, and other values loaded from credentials.
  See Credentials section for more information on how these are set.

#### Help Files

In order to integrate with `samus show-cmd <stage> <command>` syntax, your
command should include a file named `your-command.help.md` in the same directory
as the command script itself. These files are Markdown-formatted files and
should follow the same structure of the built-in command help files:

```
Short description of command.

* Files:
  * Description of what the command line arguments are

* Arguments:
  * argname: Documentation for argument
```

Notes:

- The first line of the help file is used as the summary in the `show-cmd`
  listing.
- Never omit a section. If a command has no files or arguments, use "(none)"
  as the list item text.

### Credentials

Custom credentials are just flat files or executables in the `credentials/`
directory of your custom package. When you use the "credentials" section in
a publish action of the manifest, the value should match the filename of
a file in one of your credentials directories. For instance, for the
`my-credentials-key` value in our manifest examples, you should have:

```
.samus/samus_config/credentials/my-credentials-key
```

This file is either a flat file with the format:

```
Key: THE_API_KEY
Secret: THE_SECRET
```

Or, alternatively, an _executable_ which prints the above format to standard
out.

These values are read in by Samus and get exposed as `$__CREDS_KEY` and
`$__CREDS_SECRET` respectively in Samus commands. You can provide other
metadata as well, which would be included as `$__CREDS_NAME` (for the
line "NAME: value").

## Manifest File Format

The following section defines the manifest formats for the samus.json build
manifest as well as the manifest.json stored in release packages.

### Base Format

The base format is defined as follows:

```js
{
  "actions": [
    {
      "action": "COMMAND_NAME",   // [required] command name to execute
      "files": ["file1", ...],    // optional list of files
      "arguments": {              // optional map of arguments to pass to cmd
        "key": "value",           // each key is passed in as _key in ENV
        // ... (optional) more keys ...
      },
      "pwd": "path"               // optional path to execute command from
      "credentials": "KEY",       // optional credentials to load for cmd
    },
    // ... (optional) more action items ...
  ]
}
```

All manifests include a list of "actions", known individually as action items.
Each action item has a single required property, "action", which is the command
to execute for the action (found in `samus show-cmd`). An optional list of
files are passed into the command as command line arguments, and the "arguments"
property is a map of keys to values passed in as environment variables with a
"\_" prefix (key "foo" is set as environment variable "\_foo"). Optional
credentials are loaded from the credentials directory.

### Build Manifest Format

The build manifest format is similar to the above but allows for two extra keys
in each action item called "publish" and "condition".

#### "publish" Property

The "publish" property should contain the action item that is added to the
final manifest.json built into the release package if the action item is
evaluated (condition matches and command successfully executes). If a "files"
property is set on the parent action item, that property is copied into the
publish action by default, but it can be overridden.

Here is an example build manifest showing the added use of the "publish"
property:

```js
{
  "actions": [
    {
      "action": "readme-update",
      "files": ["README.txt"],
      "publish": {
        "action": "readme-publish"
        "arguments": {
          "host": "www.mywebsite.com"
        },
        "credentials": "www.mywebsite.com"
      }
    },
    {
      "action": "readme-build",
      "files": ["README.txt"],
      "publish": {
        "action": "readme-publish"
        "arguments": {
          "files": ["README.html"], // override files property
          "host": "www.mywebsite.com"
        },
        "credentials": "www.mywebsite.com"
      }
    }
  ]

}
```

#### "condition" Property

The "condition" property is a Ruby expression that is evaluated for truthiness
to decide if the action item should be evaluated or skipped. A common use for
this is to take action based on the version (see "$version" variable section
below). The following example runs an action item only for version 2.0+ of a
release:

```js
{
  "action": "rake-task",
  "arguments": { "task": "assets:package" },
  "condition": "'$version' > '2.0'"
}
```

#### "$version" Variable

A special variable "$version" is interpolated when loading the build manifest.
This variable can appear anywhere in the JSON document, and is interpolated
before any actions or conditions are evaluated.

## Contributing & TODO

Please help by contributing commands that Samus can use to build or publish
code. Integration with different package managers would be helpful, as well
as improving the kinds of build-time tasks that are exposed.

## Copyright

Samus was created by Loren Segal in 2014 and is available under MIT license.
