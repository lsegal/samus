# Samus

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

## Usage

Samus is driven by a manifest file that describes the steps to perform when
building or publishing a release. You can just use Samus to publish, or you
can use it for both, it's your choice.

### Publishing

If you can handle building all of your assets on your own, you can use Samus
just to publish your code. Create a manifest file called manifest.json and
put it in a directory with all of your assets. The manifest file is just a
list of discrete actions like so (minus comments):

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

Commands in Samus are just shell scripts. Samus passes all argument values
(the keys from the "arguments" section of the manifest) in as environment
variables with a prefixed underscore. For example, the `rake-task` command
is just: 

```sh
#!/bin/sh

rake $_task
```

The `$_task` variable is the "task" argument from the manifest.

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

Or, alternatively, an *executable* which prints the above format to standard
out.

These values are read in by Samus and get exposed as `$__creds_key` and
`$__creds_secret` respectively in Samus commands. You can provide other
metadata as well, which would be included as `$__creds_name` (for the
line "NAME: value").

## Contributing & TODO

Please help by contributing commands that Samus can use to build or publish
code. Integration with different package managers would be helpful, as well
as improving the kinds of build-time tasks that are exposed.

## Copyright

Samus was created by Loren Segal in 2014 and is available under BSD license.
