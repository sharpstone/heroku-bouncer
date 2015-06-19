require 'heroku/bouncer/middleware'
require 'rack/builder'
require 'omniauth-heroku'

class Heroku::Bouncer::Builder

  def self.new(app, options = {})
    builder = Rack::Builder.new
    id, secret, scope = extract_options!(options)
    unless options[:disabled]
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

    if id.nil? || secret.nil? || id.empty? || secret.empty?
      $stderr.puts "[fatal] heroku-bouncer: OAuth ID or secret not set, middleware disabled"
      options[:disabled] = true
    end

    # we have to do this here because we wont have id+secret later
    if options[:secret].nil?
      $stderr.puts "[warn] heroku-bouncer: :secret is missing, using oauth id + secret as secret"
      options[:secret] = id.to_s + secret.to_s
    end

    unless options[:disabled]
      [:herokai_only, :allow_if].each do |option|
        $stderr.puts "[fatal] heroku-bouncer: #{option} is no longer supported. For safety, the middleware is disabled. Use `allow_if_user` instead."
        options[:disabled] = true
      end
    end

    [id, secret, scope]
  end
end
