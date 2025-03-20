# tl;dr

PRs welcome. Please write tests, add an entry to CHANGELOG.md for your
change, and if the change is user-facing, update README.md.

# Contributing

Contributions welcome! Here are some ways you can help:

* by using alpha, beta, and prerelease versions
* by reporting bugs
* by suggesting new features
* by writing or editing documentation
* by writing tests or specifications
* by writing code (**no patch is too small!** Fix typos, add comments, etc)
* by refactoring code
* by closing [issues][]
* by reviewing patches

[issues]: https://github.com/heroku/heroku-bouncer/issues

## Submitting an Issue

We use the [GitHub issue tracker][issues] to track bugs and features.
Before submitting a bug report or feature request, check to make sure it
hasn't already been submitted. When submitting a bug report, please
include a [Gist][] that includes a stack trace and any details that may
be necessary to reproduce the bug, including your gem version, Ruby
version, and operating system.  Ideally, a bug report should include a
pull request with failing specs.

[Gist]: https://gist.github.com/

## Getting Started Locally

Fork, then clone the repo:

    git clone git@github.com:your-username/heroku-bouncer.git

Bundle install using your preferred arguments:

    bundle install -j8 --path .bundle

Make sure the tests pass:

    bundle exec rake

## Submitting a Pull Request

1. [Fork the repository.][fork]
2. [Create a topic branch.][branch]
3. Implement your feature or bug fix. Please include tests and a
   proposed change to the `CHANGELOG.md` file.
4. Make sure the tests pass using `bundle exec rake`.
5. Please try to remove any trailing whitespace and make sure all files
   end in a newline. `git diff --check` before committing can help.
6. Add, commit, and push your changes.
7. [Submit a pull request.][pr]

[fork]: http://help.github.com/fork-a-repo/
[branch]: http://learn.github.com/p/branching.html
[pr]: http://help.github.com/send-pull-requests/

## Creating a New Rubygems Release

These steps assume you are an owner of the gem on Rubygems, you can find the full list of owners [here](https://rubygems.org/gems/heroku-bouncer).

### 1. Prepare for the Release:

First, ensure all the necessary PRs have been merged and the [Changelog](https://github.com/sharpstone/heroku-bouncer/blob/master/CHANGELOG.md) has been updated with a new section that reflects all of the changes in this release.

From the main branch, open the [gemspec file](https://github.com/sharpstone/heroku-bouncer/blob/db91a01c602790b043c96356562dcc72149402f8/heroku-bouncer.gemspec#L3), locate the `spec.version = "..."` line then update the version number accordingly (e.g., from 1.0.0 to 1.1.0). Save the gemspec file.

### 2. Create a Git Release:

Commit your changes to the repository with `git commit -am "Preparing v1.x.x release"`

Create the release using the Github CLI [interactive release command](https://cli.github.com/manual/gh_release_create):

```bash
gh release create v1.x.x
```

Selecting these options when prompted:

```bash
? Title (optional): v1.0.3
? Release notes: Write using generated notes as template
? Is this a prerelease?: No
? Submit?: Publish release
https://github.com/sharpstone/heroku-bouncer/releases/tag/v1.0.3
```

### 3. Building and Packaging the Gem:

Build the Gem:

```bash
gem build heroku-bouncer.gemspec
```

Which should output:

```bash
  Successfully built RubyGem
  Name: heroku-bouncer
  Version: 1.0.3
  File: heroku-bouncer-1.0.3.gem
```

This will create a .gem file in the same directory. Note: These files are not committed to the repository.

### 4. Publishing to RubyGems.org:

Ensure you have a RubyGems.org account and have signed in with `gem signin`.

Push the Gem:

```
gem push heroku-bouncer-1.x.x.gem
```

Replace heroku-bouncer-1.x.x.gem with the name of the .gem file created in the previous step.

The gem will be uploaded to RubyGems.org.

Fin.
