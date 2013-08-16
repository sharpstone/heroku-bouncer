require 'sinatra/base'
require 'omniauth-heroku'
require 'faraday'
require 'multi_json'
require 'encrypted_cookie'

unless defined?(Heroku)
  module Heroku; end
end

class Heroku::Bouncer < Sinatra::Base

  $stderr.puts "[warn] heroku-bouncer: HEROKU_ID detected, please use HEROKU_OAUTH_ID instead" if ENV.has_key?('HEROKU_ID')
  $stderr.puts "[warn] heroku-bouncer: HEROKU_SECRET detected, please use HEROKU_OAUTH_SECRET instead" if ENV.has_key?('HEROKU_SECRET')

  ID = (ENV['HEROKU_OAUTH_ID'] || ENV['HEROKU_ID']).to_s
  SECRET = (ENV['HEROKU_OAUTH_SECRET'] ||  ENV['HEROKU_SECRET']).to_s

  enable :raise_errors
  disable :show_exceptions

  use Rack::Session::EncryptedCookie,
    :secret => (ENV['COOKIE_SECRET'] || (ID + SECRET)).to_s,
    :expire_after => 8 * 60 * 60,
    :key => (ENV['COOKIE_NAME'] || '_bouncer_session').to_s

  # sets up the /auth/heroku endpoint
  unless ID.empty? || SECRET.empty?
    use OmniAuth::Builder do
      provider :heroku, ID, SECRET
    end
  end

  def initialize(app, options = {})
    if ID.empty? || SECRET.empty?
      $stderr.puts "[fatal] heroku-bouncer: HEROKU_OAUTH_ID or HEROKU_OAUTH_SECRET not set, middleware disabled"
      @app = app
      @disabled = true
      # super is not called; we're not using sinatra if we're disabled
    else
      super(app)
      @herokai_only = extract_option(options, :herokai_only, false)
      @expose_token = extract_option(options, :expose_token, false)
      @expose_email = extract_option(options, :expose_email, true)
      @expose_user = extract_option(options, :expose_user, true)
    end
  end

  def call(env)
    @disabled ? @app.call(env) : super(env)
  end

  before do
    if session[:user]
      expose_store
    elsif ! %w[/auth/heroku/callback /auth/heroku /auth/failure /auth/sso-logout /auth/logout].include?(request.path)
      session[:return_to] = request.url
      redirect to('/auth/heroku')
    end
  end

  # callback when successful, time to save data
  get '/auth/heroku/callback' do
    session[:user] = true
    token = request.env['omniauth.auth']['credentials']['token']
    if @expose_email || @expose_user || @herokai_only
      user = fetch_user(token)
      if @herokai_only && !user['email'].end_with?("@heroku.com")
        url = @herokai_only.is_a?(String) ? @herokai_only : 'https://www.heroku.com'
        redirect to(url) and return
      end
      store(:user, user) if @expose_user
      store(:email, user['email']) if @expose_email
    end
    store(:token, token) if @expose_token
    redirect to(session.delete(:return_to) || '/')
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
    redirect to("#{auth_url}/logout")
  end

  # logout but only locally
  get '/auth/logout' do
    destroy_session
    redirect to("/")
  end

private

  def destroy_session
    session = nil if session
  end

  def extract_option(options, option, default = nil)
    options.has_key?(option) ? options[option] : default
  end

  def fetch_user(token)
    MultiJson.decode(
      Faraday.new(ENV["HEROKU_API_URL"] || "https://api.heroku.com/").get('/account') do |r|
        r.headers['Accept'] = 'application/json'
        r.headers['Authorization'] = "Bearer #{token}"
      end.body)
  end

  def store(key, value)
    session[:store] ||= {}
    session[:store][key] = value
  end

  def expose_store
    session[:store].each_pair do |key, value|
      request.env["bouncer.#{key}"] = value
    end
  end

end
