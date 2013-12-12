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
      @session_sync_nonce = extract_option(options, :session_sync_nonce, nil)
      @allow_anonymous = extract_option(options, :allow_anonymous, nil)
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

  before do
    if session_nonce_mismatch?
      if @session_sync_nonce && session_nonce_cookie.to_s.empty?
        destroy_session
        redirect to(request.url)
      else
        require_authentication
      end
    end

    if store_read(:user)
      if expired? && !auth_request?
        require_authentication
      else
        expose_store
      end
    elsif !anonymous_request_allowed?
      require_authentication
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
    store_write(@session_sync_nonce.to_sym, session_nonce_cookie) if @session_sync_nonce
    store_write(:token, token) if @expose_token
    store_write(:expires_at, Time.now.to_i + 3600 * 8)
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

  # login, setting the URL to return to
  get '/auth/login' do
    store_write(:return_to, params['return_to'])
    redirect to('/auth/heroku')
  end

private

  def unlock_session_data(env, &block)
    decrypt_store(env)
    yield
  ensure
    encrypt_store(env)
  end

  def auth_request?
    %w[/auth/heroku/callback /auth/heroku /auth/failure /auth/sso-logout /auth/logout /auth/login].include?(request.path)
  end

  def session_nonce_mismatch?
    @session_sync_nonce && (store_read(@session_sync_nonce.to_sym).to_s != session_nonce_cookie.to_s) && !auth_request?
  end

  def session_nonce_cookie
    @session_sync_nonce && request.cookies[@session_sync_nonce]
  end

  def anonymous_request_allowed?
    auth_request? || (@allow_anonymous && @allow_anonymous.call(request))
  end

  def expired?
    ts = store_read(:expires_at)
    ts.nil? || Time.now.to_i > ts
  end

  def require_authentication
    store_write(:return_to, request.url)
    redirect to('/auth/heroku')
  end

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
    store.keys.each { |k| store_delete(k) }
  end

  def expose_store
    store.each_pair do |key, value|
      request.env["bouncer.#{key}"] = value
    end
  end

end
