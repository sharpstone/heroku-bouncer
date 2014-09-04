# 0.5.0

Adds `allow_if` option, and deprecates `herokai_only` (#35). Thanks
@stillinbeta!

# 0.4.3

This release addresses options hash re-use (#34). Thanks @gregburek for
reporting!

# 0.4.2

This release limits the size of the URL stored in the session, which
could result in a cookie overflow condition

# 0.4.1

This release addresses an open redirect security vulernability
addressed in #31. Thanks @raul!

# 0.4.0

This is nearly 1.0 ready, but I would like to see some additional
changes in the following areas:

* Option refactoring. We have a huge number of options now.
* Extensibility. It should be easier to extend/inherit from
  Heroku::Bouncer to tweak its behavior. This was possible under 0.3.x
  but is no longer true in 0.4.0.
* Remove backwards compatibility support (i.e. ENV vars)

To those upgrading, please note that a great deal has changed. Backwards
compatibility with warnings has been maintained in this version, but not
throughly tested. Extensibility has not - you'll need to do some new
tricks if you have extended Heroku::Bouncer in your app.

# 0.4.0.pre\*

Pre-releases changes were not documented. See 0.4.0 for details.

# 0.3.4

Fix a redirect loop (#16).

# 0.3.3

Fix bug with `herokai_only` writing to session even if the user is not
Herokai.

# 0.3.2

Fix bug with creating an anonymous Module object for the `Heroku`
constant.

# 0.3.1

Fix a bug with session destruction.

# 0.3.0

Switch to using the encrypted cookie gem for session storage.

# 0.2.1

Don't store data in the session until after checking email address.

# 0.2.0

* Prefer `HEROKU_OAUTH_ID` and `HEROKU_OAUTH_SECRET` environment
  variables.
* Check these variables for values, and disable middleware if they are
  not present.

# 0.1.0

First "production" release.
