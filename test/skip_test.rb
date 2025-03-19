require_relative "test_helper"

describe Heroku::Bouncer do
  include Rack::Test::Methods

  context "skip" do
    before do
      @app = app_with_bouncer do
        { skip: lambda { |env| env['PATH_INFO'] == '/skip-me' } }
      end
    end

    it "skips bouncer for the requests that fulfill the requirements" do
      get '/skip-me'
      assert_equal 'skip-me', last_response.body

      session = decode_cookie(last_response.cookies["rack.session"].first)

      refute session.has_key?("bouncer"), "Session had bouncer data"
    end

    it "applies bouncer to those requests that don't fulfill the requirements" do
      get '/hi'
      assert_requires_authentication

      session = decode_cookie(last_response.cookies["rack.session"].first)

      assert session.has_key?("bouncer"), "Session had bouncer data"
    end

    private

    if defined?(::Rack::Session::Encryptor)
      def decode_cookie(raw_cookie)
        @encryptor ||= Rack::Session::Encryptor.new(default_bouncer_config.fetch(:secret))
        @encryptor.decrypt(raw_cookie)
      rescue Rack::Session::Encryptor::InvalidSignature
        {}
      end
    else
      def decode_cookie(raw_cookie)
        unescaped_cookie = URI::Parser.new.unescape(raw_cookie.split("\n").join)
        Marshal.load(Base64.decode64(unescaped_cookie.split("--").first))
      end
    end
  end
end
