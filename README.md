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

```
$ ./pr-builder.sh <github-user> <personal access token> <repo>
```

Example:

```
$ ./pr-builder.sh grav abc123beefbeefbeef grav/my-repo
```

Make sure the PR-branch contains a `test.sh` script in the root.

To generate a personal access token, visit this page:
https://github.com/settings/tokens

