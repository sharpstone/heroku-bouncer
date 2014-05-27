require 'heroku/bouncer/middleware'
require 'rack/builder'
require 'omniauth-heroku'

class Heroku::Bouncer::Builder

  def self.new(app, options = {})
    builder = Rack::Builder.new
    id, secret, scope = extract_options!(options)
    unless id.empty? || secret.empty?
      builder.use OmniAuth::Builder do
        provider :heroku, id, secret, :scope => scope
      end
    end
    builder.run Heroku::Bouncer::Middleware.new(app, options)
    builder
  end

  def self.extract_options!(options)
    oauth = options[:oauth] || {}
    id = oauth[:id]
    secret = oauth[:secret]
    scope = oauth[:scope] || 'identity'

    if id.nil? && (ENV.has_key?('HEROKU_ID') || ENV.has_key?('HEROKU_OAUTH_ID'))
      $stderr.puts "[warn] heroku-bouncer: HEROKU_ID or HEROKU_OAUTH_ID detected in environment, please pass in :oauth hash instead"
      id = ENV['HEROKU_OAUTH_ID'] || ENV['HEROKU_ID']
    end

    if secret.nil? && (ENV.has_key?('HEROKU_SECRET') || ENV.has_key?('HEROKU_OAUTH_SECRET'))
      $stderr.puts "[warn] heroku-bouncer: HEROKU_SECRET or HEROKU_OAUTH_SECRET detected in environment, please pass in :oauth hash instead"
      secret = ENV['HEROKU_OAUTH_SECRET'] || ENV['HEROKU_SECRET']
    end

    if id.nil? || secret.nil?
      $stderr.puts "[fatal] heroku-bouncer: HEROKU_OAUTH_ID or HEROKU_OAUTH_SECRET not set, middleware disabled"
      options[:disabled] = true
    end

    # we have to do this here because we wont have id+secret later
    if options[:secret].nil?
      if ENV.has_key?('COOKIE_SECRET')
        $stderr.puts "[warn] heroku-bouncer: COOKIE_SECRET detected in environment, please pass in :secret instead"
        options[:secret] = ENV['COOKIE_SECRET']
      else
        $stderr.puts "[warn] heroku-bouncer: :secret is missing, using id + secret"
        options[:secret] = id.to_s + secret.to_s
      end
    end

    [id, secret, scope]
  end
end
