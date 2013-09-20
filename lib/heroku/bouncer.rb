require 'sinatra/base'
require 'omniauth-heroku'
require 'faraday'
require 'multi_json'
require 'openssl'

unless defined?(Heroku)
  module Heroku; end
end

class Heroku::Bouncer < Sinatra::Base

  $stderr.puts "[warn] heroku-bouncer: HEROKU_ID detected, please use HEROKU_OAUTH_ID instead" if ENV.has_key?('HEROKU_ID')
  $stderr.puts "[warn] heroku-bouncer: HEROKU_SECRET detected, please use HEROKU_OAUTH_SECRET instead" if ENV.has_key?('HEROKU_SECRET')

  ID            = (ENV['HEROKU_OAUTH_ID'] || ENV['HEROKU_ID']).to_s
  SECRET        = (ENV['HEROKU_OAUTH_SECRET'] ||  ENV['HEROKU_SECRET']).to_s
  COOKIE_SECRET = (ENV['COOKIE_SECRET'] || (ID + SECRET)).to_s

  enable :raise_errors
  disable :show_exceptions

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
    if @disabled
      @app.call(env)
    else
      decrypt_store(env)
      status, headers, body = super(env)
      encrypt_store(env)
      [status, headers, body]
    end
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
    redirect to("#{auth_url}/logout")
  end

  # logout but only locally
  get '/auth/logout' do
    destroy_session
    redirect to("/")
  end

private

  def decrypt_store env
    session_data = env["rack.session"][:bouncer]

    if session_data
      if session_data = decrypt(session_data)
        session_data, digest = session_data.split("--")
        session_data = nil unless digest == generate_hmac(session_data)
      end
    end

    begin
      session_data = session_data.unpack("m*").first
      session_data = Marshal.load(session_data)
      env["rack.session"][:bouncer] = session_data
    rescue
      env["rack.session"][:bouncer] = Hash.new
    end

  end

  def encrypt_store env
    session_data = Marshal.dump(env["rack.session"][:bouncer])
    session_data = [session_data].pack("m*")

    session_data = "#{session_data}--#{generate_hmac(session_data)}"

    session_data = encrypt(session_data)
    env["rack.session"][:bouncer] = session_data
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

  def encrypt(str)
    aes = OpenSSL::Cipher::Cipher.new('aes-128-cbc').encrypt
    aes.key = COOKIE_SECRET
    iv = OpenSSL::Random.random_bytes(aes.iv_len)
    aes.iv = iv
    [iv + (aes.update(str) << aes.final)].pack('m0')
  end

  # decrypts string. returns nil if an error occurs
  #
  # returns nil if openssl raises an error during decryption (likely
  # someone is tampering with the session data, or the sinatra user was
  # previously using Cookie and has just switched to EncryptedCookie), and
  # will also return nil if the text to decrypt is too short to possibly be
  # good aes data.
  def decrypt(str)
    str = str.unpack('m0').first
    aes = OpenSSL::Cipher::Cipher.new('aes-128-cbc').decrypt
    aes.key = COOKIE_SECRET
    iv = str[0, aes.iv_len]
    aes.iv = iv
    crypted_text = str[aes.iv_len..-1]
    return nil if crypted_text.nil? || iv.nil?
    aes.update(crypted_text) << aes.final
  rescue
    nil
  end

  def generate_hmac(data)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, COOKIE_SECRET, data)
  end

end
