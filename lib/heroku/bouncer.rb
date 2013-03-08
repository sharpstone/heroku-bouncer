require 'sinatra/base'
require 'omniauth-heroku'
require 'heroku-api'

Heroku ||= Module.new

class Heroku::Bouncer < Sinatra::Base

  enable :sessions
  set :session_secret, ENV['HEROKU_ID'].to_s + ENV['HEROKU_SECRET'].to_s

  # sets up the /auth/heroku endpoint
  use OmniAuth::Builder do
    provider :heroku, ENV['HEROKU_ID'], ENV['HEROKU_SECRET']
  end

  def initialize(app, options = {})
    super(app)
    @herokai_only = extract_option(options, :herokai_only, false)
    @expose_token = extract_option(options, :expose_token, false)
    @expose_email = extract_option(options, :expose_email, true)
    @expose_user = extract_option(options, :expose_user, true)
  end

  def extract_option(options, option, default = nil)
    options.has_key?(option) ? options[option] : default
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

  before do
    if session[:user]
      expose_store
    elsif ! %w[/auth/heroku/callback /auth/heroku /auth/failure].include?(request.path)
      session[:return_to] = request.url
      redirect to('/auth/heroku')
    end
  end

  # callback when successful, time to save data
  get '/auth/heroku/callback' do
    session[:user] = true
    token = request.env['omniauth.auth']['credentials']['token']
    store(:token, token) if @expose_token
    if @expose_email || @expose_user || @herokai_only
      api = Heroku::API.new(:api_key => token)
      user = api.get_user.body if @expose_user
      store(:user, user) if @expose_user
      store(:email, user['email']) if @expose_email

      if @herokai_only && user['email'] !~ /@heroku\.com$/
        redirect to('/auth/failure') and return
      end
    end
    redirect to(session.delete(:return_to) || '/')
  end

  # user decided  not to give us access?
  get '/auth/failure' do
    session.destroy
    auth_url = ENV["HEROKU_AUTH_URL"] || "https://api.heroku.com"
    redirect to("#{auth_url}/logout")
  end

end
