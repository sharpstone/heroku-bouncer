require 'sinatra/base'
require 'faraday'
require 'securerandom'

require 'heroku/bouncer/json_parser'
require 'heroku/bouncer/decrypted_hash'

class Heroku::Bouncer::Middleware < Sinatra::Base

  DecryptedHash = ::Heroku::Bouncer::DecryptedHash

  enable :raise_errors
  disable :show_exceptions

  def initialize(app, options = {})
    if options[:disabled]
      @app = app
      @disabled = true
      # super is not called; we're not using sinatra if we're disabled
    else
      super(app)
      @cookie_secret = extract_option(options, :secret, SecureRandom.base64(32))
      @herokai_only = extract_option(options, :herokai_only, false)
      @expose_token = extract_option(options, :expose_token, false)
      @expose_email = extract_option(options, :expose_email, true)
      @expose_user = extract_option(options, :expose_user, true)
    end
  end

  def call(env)
    if @disabled
      @app.call(env)
    else
      unlock_session_data(env) do
        super(env)
      end
    end
  end

  def unlock_session_data(env, &block)
    decrypt_store(env)
    return_value = yield
    encrypt_store(env)
    return_value
  end

  before do
    if store_read(:user)
      expose_store
    elsif ! %w[/auth/heroku/callback /auth/heroku /auth/failure /auth/sso-logout /auth/logout].include?(request.path)
      store_write(:return_to, request.url)
      redirect to('/auth/heroku')
    end
  end

  # callback when successful, time to save data
  get '/auth/heroku/callback' do
    token = request.env['omniauth.auth']['credentials']['token']
    if @expose_email || @expose_user || @herokai_only
      user = fetch_user(token)
      if @herokai_only && !user['email'].end_with?("@heroku.com")
        url = @herokai_only.is_a?(String) ? @herokai_only : 'https://www.heroku.com'
        redirect to(url) and return
      end
      @expose_user ? store_write(:user, user) : store_write(:user, true)
      store_write(:email, user['email']) if @expose_email
    else
      store_write(:user, true)
    end

    store_write(:token, token) if @expose_token
    redirect to(store_delete(:return_to) || '/')
  end

  # something went wrong
  get '/auth/failure' do
    destroy_session
    redirect to("/")
  end

  # logout, single sign-on style
  get '/auth/sso-logout' do
    destroy_session
    auth_url = ENV["HEROKU_AUTH_URL"] || "https://id.heroku.com"
    logout_url = "#{auth_url}/logout"

    # id.heroku.com whitelists this return_to param, as any auth provider should do
    logout_url += "?url=#{params['return_to']}" if params['return_to']

    redirect to(logout_url)
  end

  # logout but only locally
  get '/auth/logout' do
    destroy_session
    redirect to("/")
  end

private

  def extract_option(options, option, default = nil)
    options.has_key?(option) ? options[option] : default
  end

  def fetch_user(token)
    ::Heroku::Bouncer::JsonParser.call(
      Faraday.new(ENV["HEROKU_API_URL"] || "https://api.heroku.com/").get('/account') do |r|
        r.headers['Accept'] = 'application/json'
        r.headers['Authorization'] = "Bearer #{token}"
      end.body)
  end

  def decrypt_store(env)
    env["rack.session"][:bouncer] =
      DecryptedHash.unlock(env["rack.session"][:bouncer], @cookie_secret)
  end

  def encrypt_store(env)
    env["rack.session"][:bouncer] =
      env["rack.session"][:bouncer].lock(@cookie_secret)
  end

  def store
    session[:bouncer]
  end

  def store_write(key, value)
    store[key] = value
  end

  def store_read(key)
    store.fetch(key, nil)
  end

  def store_delete(key)
    store.delete(key)
  end

  def destroy_session
    session = nil if session
  end

  def expose_store
    store.each_pair do |key, value|
      request.env["bouncer.#{key}"] = value
    end
  end

end
