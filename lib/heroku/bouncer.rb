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
    redirect to("#{auth_url}/logout")
  end

  # logout but only locally
  get '/auth/logout' do
    destroy_session
    redirect to("/")
  end

  # Encapsulates encrypting and decrypting a hash of data. Does not store the
  # key that is passed in.
  class DecryptedHash < Hash

    Lockbox = ::Heroku::Bouncer::Lockbox

    def initialize(decrypted_hash = nil)
      super
      replace(decrypted_hash) if decrypted_hash
    end

    def self.unlock(data, key)
      if data && data = Lockbox.new(key).unlock(data)
        data, digest = data.split("--")
        if digest == Lockbox.generate_hmac(data, key)
          data = data.unpack('m*').first
          data = Marshal.load(data)
          new(data)
        else
          new
        end
      else
        new
      end
    end

    def lock(key)
      # marshal a Hash, not a DecryptedHash
      data = {}.replace(self)
      data = Marshal.dump(data)
      data = [data].pack('m*')
      data = "#{data}--#{Lockbox.generate_hmac(data, key)}"
      Lockbox.new(key).lock(data)
    end

  private

    def self.generate_hmac(data, key)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, key, data)
    end
  end

  class Lockbox < BasicObject

    def initialize(key)
      @key = key
    end

    def lock(str)
      aes = OpenSSL::Cipher::Cipher.new('aes-128-cbc').encrypt
      aes.key = @key
      iv = OpenSSL::Random.random_bytes(aes.iv_len)
      aes.iv = iv
      [iv + (aes.update(str) << aes.final)].pack('m0')
    end

    # decrypts string. returns nil if an error occurs
    #
    # returns nil if openssl raises an error during decryption (data
    # manipulation, key change, implementation change), or if the text to
    # decrypt is too short to possibly be good aes data.
    def unlock(str)
      str = str.unpack('m0').first
      aes = OpenSSL::Cipher::Cipher.new('aes-128-cbc').decrypt
      aes.key = @key
      iv = str[0, aes.iv_len]
      aes.iv = iv
      crypted_text = str[aes.iv_len..-1]
      return nil if crypted_text.nil? || iv.nil?
      aes.update(crypted_text) << aes.final
    rescue
      nil
    end

  end

private

  def decrypt_store(env)
    env["rack.session"][:bouncer] =
      DecryptedHash.unlock(env["rack.session"][:bouncer], COOKIE_SECRET)
  end

  def encrypt_store(env)
    env["rack.session"][:bouncer] =
      env["rack.session"][:bouncer].lock(COOKIE_SECRET)
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


end
