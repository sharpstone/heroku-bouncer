# Heroku Bouncer

Heroku Bouncer is a Rack middleware (implemented in Sinatra) that
requires Heroku OAuth on all requests.

## Use

1. Create your OAuth client using `/auth/heroku/callback` as your
   callback endpoint:

    ```sh
    heroku clients:create likeaboss https://likeaboss.herokuapp.com/auth/heroku/callback
    ```

2. Set `HEROKU_OAUTH_ID` and `HEROKU_OAUTH_SECRET` in your environment.
3. Optionally, set the `COOKIE_SECRET` environment variable to a long
   random string. Otherwise, the OAuth ID and secret are concatenated
   for use as a secret.
4. Use the middleware:

    ```ruby
    require 'heroku/bouncer'
    require 'your_app'

    use Heroku::Bouncer
    run YourApp
    ```

## Options

There are 4 boolean options you can pass to the middleware:

* `herokai_only`: Automatically redirects non-Heroku accounts to
  `www.heroku.com`. Alternatively, pass a valid URL and non-Herokai will
  be redirected there. Default: `false`
* `expose_token`: Expose the OAuth token in the session, allowing you to
  make API calls as the user. Default: `false`
* `expose_email`: Expose the user's email address in the session.
  Default: `true`
* `expose_user`: Expose the user attributes in the session. Default:
  `true`

You use these by passing a hash to the `use` call, for example:

```ruby
use Heroku::Bouncer, expose_token: true
```

## How to get the data

Based on your choice of the expose options above, the middleware adds
the following keys to your request environment:

* `bouncer.token`
* `bouncer.email`
* `bouncer.user`

You can access this in your Rack app by reading `request.env[key]`.

## Using the Heroku API

If you set `expose_token` to `true`, you'll get an API token that you
can use to make Heroku API calls on behalf of the logged-in user using
[heroku.rb](https://github.com/heroku/heroku.rb).

```ruby
heroku = Heroku::API.new(:api_key => request.env["bouncer.token"])
apps = heroku.get_apps.body
```

Keep in mind that this adds substantial security risk to your
application.

## Logging out

Send users to `/auth/sso-logout` if logging out of Heroku is
appropriate, or `/auth/logout` if you only wish to logout of your app.
The latter will redirect to `/`, which may result is the user being
logging in again.

## Conditionally enable the middleware

Don't want to OAuth on every request? Use a middleware to conditionally
enable this middleware, like
[Rack::Builder](http://rack.rubyforge.org/doc/Rack/Builder.html).
Alternatively, [use inheritance to extend the middleware to act any way
you like](https://gist.github.com/wuputah/5534428).

## There be dragons

* There's no tests yet. You may encounter bugs. Please report them (or
  fix them in a pull request).
