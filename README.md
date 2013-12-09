# Heroku Bouncer

Heroku Bouncer is a Rack middleware (implemented in Sinatra) that
requires Heroku OAuth on all requests.

## Demo

[heroku-bouncer-demo](https://github.com/schneems/heroku-bouncer-demo) is a
Sinatra app that uses heroku-bouncer.

## Use

1. Install the Heroku OAuth CLI plugin.

    ```sh
    heroku plugins:install git://github.com/heroku/heroku-oauth.git
    ```

2. Create your OAuth client using `/auth/heroku/callback` as your
   callback endpoint. Use `http://localhost:5000/auth/heroku/callback`
   for local development with Foreman.

    ```sh
    heroku clients:register localhost http://localhost:5000/auth/heroku/callback
    heroku clients:register myapp https://myapp.herokuapp.com/auth/heroku/callback
    ```

3. Configure the middleware as follows:

    **Rack**

    `Heroku::Bouncer` requires a session middleware to be mounted above
    it. Pure Rack apps will need to add such a middleware if they don't
    already have one. In `config.ru`:

    ```ruby
    require 'rack/session/cookie'
    require 'heroku/bouncer'
    require 'my_app'

    # use `openssl rand -base64 32` to generate a secret
    use Rack::Session::Cookie, secret: "..."
    use Heroku::Bouncer,
      oauth: { id: "...", secret: "..." }, secret: "..."
    run MyApp
    ```

    **Sinatra**

    `Heroku::Bouncer` can be run like a Rack app, but since a Sinatra
    app can mount Rack middleware, it may be easier to mount it inside
    the app and use Sinatra's session.

    ```ruby
    class MyApp < Sinatra::Base
      ...
      enable :sessions, secret: "..."
      use ::Heroku::Bouncer,
        oauth: { id: "...", secret: "..." }, secret: "..."
      ...
    ```

    **Rails**

    Add a middleware configuration line to `config/application.rb`:

    ```ruby
    config.middleware.use ::Heroku::Bouncer,
      oauth: { id: "...", secret: "..." }, secret: "..."
    ```

4. Fill in the required settings `:oauth` and `:secret` as explained
   below.

## Settings

Two settings are **required**:

* `oauth`: Your OAuth credentials as a hash - `:id` and `:secret`.
* `secret`: A random string used as an encryption secret used to secure
  the user information in the session.

Using environment variables for these is recommended, for example:

```ruby
use Heroku::Bouncer,
  oauth: { id: ENV['HEROKU_OAUTH_ID'], secret: ENV['HEROKU_OAUTH_SECRET'] },
  secret: ENV['HEROKU_BOUNCER_SECRET']
```

There are 7 additional options you can pass to the middleware:

* `oauth[:scope]`: The [OAuth scope][] to use when requesting the OAuth
  token. Default: `identity`.
* `herokai_only`: Automatically redirects non-Heroku accounts to
  `www.heroku.com`. Alternatively, pass a valid URL and non-Herokai will
  be redirected there. Default: `false`
* `expose_token`: Expose the OAuth token in the session, allowing you to
  make API calls as the user. Default: `false`
* `expose_email`: Expose the user's email address in the session.
  Default: `true`
* `expose_user`: Expose the user attributes in the session. Default:
  `true`
* `session_sync_nonce`: If present, determines the name of a cookie shared across properties under a same domain in order to keep their sessions synchronized. Default: `nil`
* `allow_anonymous`: Accepts a lambda that gets called with each request. If the lambda evals to true, the request will not enforce authentication (e.g: `allow_anonymous: lambda { |req| !/\A\/admin/.match(req.fullpath) }` will allow anonymous requests except those with under the `/admin` path). Default: `nil`, which does not allow anonymous access to any URL.


You use these by passing a hash to the `use` call, for example:


```ruby
use Heroku::Bouncer,
  oauth: { id: "...", secret: "...", scope: "global" },
  secret: "...",
  expose_token: true
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
[heroku.rb][] .

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

> Don't want to OAuth on every request? Use a middleware to conditionally
> enable this middleware, like [Rack::Builder][].
> Alternatively, [use inheritance to extend the middleware to act any way
> you like][inheritance].

Due to changes in how the middleware stack is built, this is currently
broken in the 0.4.0 prereleases.

## There be dragons

You may encounter bugs. Please report them (or fix them in a pull request).

## Security Model: A Tale of Three Secrets

There are three secrets in use:

* A OAuth secret. Paired with the OAuth ID, this is how the Heroku
  authorizes your OAuth requests with your particular OAuth client.
* A bouncer secret. Bouncer encrypts and signs all user data placed in
  the session. This ensures such data cannot be viewed by anyone but the
  application.
* A session secret. This is used to sign the session, which validates
  the session was generated by your application. Strictly speaking,
  however, this is outside of Bouncer and is not a part of its security
  model.

In totality, Heroku Bouncer ensures session data can only be generated
and read by your application. However, they do not protect against
replay attacks if the data is obtained in its entirety. SSL and session
timeouts should be used to help mitigate this risk. CSRF tokens for any
actions that modify data are also recommended.

[Rack::Builder]: http://rack.rubyforge.org/doc/Rack/Builder.html
[inheritance]: https://gist.github.com/wuputah/5534428
[OAuth scope]: https://devcenter.heroku.com/articles/oauth#scopes
[heroku.rb]: https://github.com/heroku/heroku.rb
