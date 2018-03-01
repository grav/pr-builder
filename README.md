# GitHub Pull Request Builder

## What is it?

The script will:
- query for any open pull requests (PRs) of a repository on GitHub
- checkout the code 
- run tests via the `test.sh` script
- update status of the PR.

That's it!

It will keep a record of all PRs that are being looked at or have already been looked at,
and ignore these on next run.

To make it run continuously, use something like `crontab`, or maybe just `tmux` with a `while sleep` loop? 
That's CI for ya right there :-)

## How do I use it?

First install `jq` with `brew`, `apt-get` etc.

The syntax for running the script is:

```
$ ./pr-builder.sh <github-user> <personal access token> <repo> <log-base-url> <workspace> <test-script>

```

`<workspace>` defaults to `workspace`, `<test-script>` defaults to `./test.sh`

Example:

```
$ ./pr-builder.sh grav abc123beefbeefbeef grav/my-repo http://example.com/logs ws ./test.sh
```

Make sure the PR-branch contains a `test.sh` script in the root (or whatever you've defined).

To generate a personal access token, visit this page:
https://github.com/settings/tokens

## TODO
- log all communication with GitHub API
- allow setting workdir from cmdline 
- describe `comment-command.sh`
- handle `fatal: reference is not a tree: <sha>` - seems to come up if PR has arrived to GitHub before commit
