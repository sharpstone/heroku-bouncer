# Heroku Bouncer

Heroku Bounder is a Rack middleware (implemented in Sinatra) that
requires Heroku OAuth on all requests.

## Use

1. Set `HEROKU_ID` and `HEROKU_SECRET` in your environment.
2. Use the middleware:

    ```ruby
    require 'heroku/bouncer'
    require 'your_app'

    use Heroku::Bouncer
    run YourApp
    ```

## Options

There are 4 boolean options you can pass to the middleware:

* `herokai_only`: Automatically redirects non-Heroku accounts to
  `www.heroku.com`. Default: `false`
* `expose_token`: Expose the OAuth token in the session, allowing you to
  make API calls as the user. Default: `false`
* `expose_email`: Expose the user's email address in the session.
  Default: `true`
* `expose_user`: Expose the user attributes in the session. Default:
  `true`

You use these by passing a hash to the `use` call, for example:

```ruby
use Heroku::Builder, expose_token: true
```

## How to get the data

Based on your choice of the expose options above, the middleware adds
the following keys to your request environment:

* `bouncer.token`
* `bouncer.email`
* `bouncer.user`

You can access this in your Rack app by reading `request.env[key]`.

## Conditionally disabling the middleware

Don't want to OAuth on every request? Use a middleware to conditionally
enable this middleware, like
[`Rack::Builder`](http://rack.rubyforge.org/doc/Rack/Builder.html).

## There be dragons

* This middleware uses a session stored in a cookie. The cookie secret
  is `HEROKU_ID + HEROKU_SECRET`. So keep these secret.
* There's no tests yet. You may encounter bugs. Please report them (or
  fix them in a pull request).
