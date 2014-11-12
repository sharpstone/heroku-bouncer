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
