# GitHub Pull Request Builder

## What is it?

The script will:
- query for any open pull requests (PRs) of a repository on GitHub
- checkout the code 
- run tests via a specified shell script
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
$ ./pr-builder.sh <github-user> <personal access token> <repo> <base-branch> <log-base-url> <context> <test-script>

```

Example:

```
$ ./pr-builder.sh grav abc123beefbeefbeef grav/my-repo master http://example.com/logs my-ci ./test.sh
```

This will test any open PR that is destined for the `master` branch.

The `context` parameter is part of the naming of the eventual status check that will be recorded on Github. If, for instance, you set the `context` parameter to `my-ci` and the base to `master`, a status check called `my-ci master` will eventually show up for the processed pull requests. You can then use Github's branch protection rules to make a status check required.

To read more about status checks, visit this page:
https://help.github.com/articles/about-status-checks/

Make sure the PR-branch contains a `test.sh` script in the root (or whatever you've defined).

To generate a personal access token, visit this page:
https://github.com/settings/tokens

## Can I see the logs?

The logs of each test run is put into `db/<commit-sha>_<base>.txt`. You can just point your webserver to that directory to expose them to a browser.

## But ... I want it to do deployment

Well, you're in luck. If you set the magic env-var LATEST_COMMIT to something, `pr-builder` will process the lastest commit of the specified branch. So, for example:

```
$ LATEST_COMMIT=1 ./pr-builder grav abc123beefbeefbeef grav/my-repo master http://example.com/logs my-deploy ./launch-missiles.sh
```

Again, if you wrap it in a `while` loop, you now have continuous deployment.

## Can I please have triggers via github-comments?

Well ok ... there's a crude copy/paste of the main script in this repo, called `comment-command.sh` which does just this. Eventually, I'll refactor the two scripts into one and document it.

## TODO
- ~~describe deployment feature~~
- refactor `comment-command.sh` into main script and document it
- ~~handle `fatal: reference is not a tree: <sha>` - seems to come up if PR has arrived to GitHub before commit~~
- specify license
- specify timeout of some sort
- move config into a file

