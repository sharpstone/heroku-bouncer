# Heroku Bouncer

Heroku Bouncer is a Rack middleware (implemented in Sinatra) that
requires Heroku OAuth on all requests.

## Demo

[heroku-bouncer-demo](https://github.com/schneems/heroku-bouncer-demo) is a
Sinatra app that uses heroku-bouncer.

## Use

1. Create your OAuth client using `/auth/heroku/callback` as your
   callback endpoint. Use `http://localhost:5000/auth/heroku/callback`
   for local development with Foreman.

    ```sh
    heroku clients:register localhost http://localhost:5000/auth/heroku/callback
    heroku clients:register myapp https://myapp.herokuapp.com/auth/heroku/callback
    ```

2. Set `HEROKU_OAUTH_ID` and `HEROKU_OAUTH_SECRET` in your environment.
3. Set the `COOKIE_SECRET` environment variable to a long random string.
   Otherwise, the OAuth ID and secret are concatenated for use as a secret.
4. Use the middleware.

    **Rack, Sinatra, and Rails 4**

    Add a `use` line to `config.ru`:

    ```ruby
    require ::File.expand_path('../config/environment', __FILE__)

    use ::Heroku::Bouncer
    run Rails.application
    ```

    The middleware does not work properly when configured inside
    Rails 4.

    **Rails 3**

    Add a middleware configuration line to `config/application.rb`:

    ```ruby
    config.middleware.use ::Heroku::Bouncer
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

You can access this in Sinatra and Rails by  `request.env[key]`, e.g.
`request.env['bouncer.token']`.

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
